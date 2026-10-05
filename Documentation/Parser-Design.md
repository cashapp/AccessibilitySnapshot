# Parser design

## 1. The parser pipeline

Blue is the public API/model. Orange marks phases that read live UIKit data. Everything inside the parser box is private.

```mermaid
flowchart TD
    API["parseAccessibilityHierarchy<br/>root + layout direction + idiom + rotor limit"]
    UI["Live UIKit hierarchy"]

    subgraph PRIVATE["Private parser implementation"]
        WALK["recursiveAccessibilityHierarchy<br/>Walk children, apply visibility rules,<br/>capture container facts"]
        TREE["Structural tree: AccessibilityNode<br/>Groups own children<br/>Leaves hold CapturedElement"]
        GEOMETRY["captureSortFrames<br/>Capture sorting geometry after the tree walk"]
        CAPTURE["captureElementFields<br/>Capture element facts, display shapes,<br/>and rotor definitions in navigation order"]
        SORT["sortedNodes<br/>Project navigation boundaries<br/>Preserve explicit array slots<br/>Apply existing geometry comparator"]
        INDEX["Assign traversalIndex<br/>to each captured leaf occurrence"]
        ORDER["orderedOutputNodes<br/>Arrange structural children using indices<br/>Preserve ownership and explicit slots"]
        CONTEXT["prepareNodes<br/>Derive element context<br/>Resolve table header child indices"]
        ROTORS["Collect rotor results<br/>Use captured definitions and language<br/>with derived context"]
        FOLD["foldNodes<br/>Build each public element from its record<br/>Invoke children-first generic constructors"]

        WALK --> TREE --> GEOMETRY --> SORT --> INDEX
        INDEX --> ORDER --> CONTEXT --> CAPTURE --> ROTORS --> FOLD
        TREE -.->|"Retained source references"| FOLD
    end

    API --> WALK
    UI --> WALK
    UI -->|"Read sorting geometry"| GEOMETRY
    UI -->|"Read element fields after preparation"| CAPTURE
    UI -->|"Live rotor searches and target reads"| ROTORS

    FOLD --> DEFAULT["Default constructors<br/>AccessibilityHierarchy tree"]
    FOLD --> CUSTOM["Your constructors<br/>Caller-defined node tree"]
    DEFAULT --> FLAT["flattenToElements<br/>Reading order from traversalIndex"]
    FOLD --> ELEMENT["Immutable AccessibilityElement<br/>Stored facts + derived context"]
    ELEMENT --> SPEECH["On access: compute description and hint<br/>from stored values"]

    classDef public fill:#e8f1ff,stroke:#3973b9,color:#111;
    classDef capture fill:#fff0da,stroke:#c47b16,color:#111;
    class API,ELEMENT,SPEECH,DEFAULT,CUSTOM,FLAT public;
    class WALK,GEOMETRY,CAPTURE,ROTORS capture;
```

| Private type | What it carries |
|---|---|
| `CapturedElement` | Source identity, captured element facts and geometry, rotor definitions/results, derived context, traversal index |
| `ContainerInfo` | Source, role, navigation/context rules, tab/table facts, portable container payload |
| `AccessibilityNode` | Either a captured leaf or a group of child nodes |

The structural walk finishes before sort-frame capture because container text getters can settle descendant layout. Sorting and context preparation consume captured data. Element fields are then captured in navigation order, followed by context-dependent rotor searches. All live reads finish before the generic fold constructs public elements and invokes caller constructors.

## 2. Structural ownership and reading order

The tree answers “who owns this?” The traversal index answers “when is this visited?”

Here, container A owns A1 and A2, while B falls between them in reading order.

```mermaid
flowchart LR
    subgraph STRUCTURE["Structural ownership"]
        ROOT["Root"]
        A["Container A"]
        A1["A1<br/>traversalIndex: 0"]
        A2["A2<br/>traversalIndex: 2"]
        B["B<br/>traversalIndex: 1"]

        ROOT --> A
        ROOT --> B
        A --> A1
        A --> A2
    end

    subgraph NAVIGATION["Reading order"]
        N1["A1 · 0"] --> N2["B · 1"] --> N3["A2 · 2"]
    end

    subgraph CALLBACKS["Children-first construction order"]
        C1["makeElement A1"]
        C2["makeElement A2"]
        C3["makeContainer A<br/>children: A1, A2"]
        C4["makeElement B"]

        C1 --> C2 --> C3 --> C4
    end
```

The structural and navigation projections share the same `CapturedElement` instances. Assigning an index or context updates the record that both projections refer to.

Constructor invocation order follows the structural fold. Consumers use the supplied traversal indices when they need reading order.

## 3. Building the public result

The private intermediate record is mutable during capture and preparation. The public element has read-only properties and computed description/hint outputs. Its context can be attached through the parser-only `addContext(_:)` SPI. The current parser still constructs the public element from its completed private record during the fold.

```mermaid
flowchart TD
    GEOMETRY["Capture structure, container facts and sort frames"]
    PREPARE["Prepare reading order and context<br/>Assign traversalIndex and context"]
    CAPTURE["Capture element facts<br/>Text, traits, language, display geometry,<br/>activation metadata, actions, content and rotor definitions"]
    ROTORS["Capture context-dependent rotor results"]
    RECORD["Completed CapturedElement"]
    SOURCE["Retained source object"]

    subgraph FOLD["Generic fold into caller-defined Node"]
        BUILD["buildElement from CapturedElement<br/>Construct from stored values"]
        ELEMENT["Immutable AccessibilityElement"]
        LEAF["makeElement<br/>element + traversalIndex + live source"]
        CONTAINER["makeContainer<br/>container + completed child nodes + live source"]

        BUILD --> ELEMENT --> LEAF
        LEAF -->|"Completed child nodes"| CONTAINER
    end

    GEOMETRY --> PREPARE --> CAPTURE --> ROTORS --> RECORD --> BUILD
    SOURCE -.->|"Leaf source argument"| LEAF
    SOURCE -.->|"Container source argument"| CONTAINER
    LEAF --> OUTPUT["Caller-defined node tree"]
    CONTAINER --> OUTPUT
    ELEMENT --> SPEECH["Computed description and hint"]
```

Each leaf constructs its public element when the generic fold reaches it. There is no separate public-element array or traversal-index lookup. All UIKit getters and rotor searches finish before the fold begins, so caller mutations do not affect later public elements.

The caller-supplied generic constructors retain their signatures:

```swift
makeElement: (AccessibilityElement, Int, NSObject) -> Node
makeContainer: (AccessibilityContainer, [Node], NSObject) -> Node
```

### Source ownership

The parser holds strong references to the original live sources during its synchronous call and passes those exact objects to the caller's constructors. All working records are local to the call; the parser keeps no source references after returning. UIKit or caller-owned objects may still retain the sources, so this does not guarantee their deallocation.

The library-supplied constructors ignore the sources; the returned `AccessibilityHierarchy` contains captured values only.

Custom constructors control their own ownership. Storing a source strongly in a returned node or elsewhere keeps it alive beyond parsing and can retain its UI hierarchy. An ownership cycle can leak those objects. Use weak references for source associations that should not extend the UI object's lifetime. The captured public values remain usable independently of the live sources.
