# Parser design

## 1. The parser pipeline

Blue is the public API/model. Orange marks the phase that reads live UIKit data. The parser keeps its working records private and stores public payloads inside them.

```mermaid
flowchart TD
    API["parseAccessibilityHierarchy<br/>root + layout direction + idiom + rotor limit"]
    UI["Live UIKit hierarchy"]

    subgraph PRIVATE["Private parser implementation"]
        WALK["recursiveAccessibilityHierarchy<br/>Entry: capture candidate container facts and policies<br/>Walk: capture leaves, rotors and table relationships<br/>Exit: complete groups from captured data"]
        TREE["Structural tree: AccessibilityNode<br/>Groups own children and container payloads<br/>Leaves hold CapturedElement"]
        SORT["sortedNodes<br/>Project navigation boundaries<br/>Preserve explicit array slots<br/>Apply existing geometry comparator"]
        INDEX["Assign traversalIndex<br/>to each captured leaf occurrence"]
        ORDER["orderedOutputNodes<br/>Arrange structural children using indices<br/>Preserve ownership and explicit slots"]
        CONTEXT["prepareNodes<br/>Attach element context with addContext<br/>Resolve table header child indices"]
        ROTORS["Format captured rotor targets<br/>Use derived context<br/>Attach results with addCustomRotors"]
        FOLD["foldNodes<br/>Pass completed public payloads and original sources<br/>to children-first generic constructors"]

        WALK --> TREE --> SORT --> INDEX
        INDEX --> ORDER --> CONTEXT --> ROTORS --> FOLD
        TREE -.->|"Retained source references"| FOLD
    end

    API --> WALK
    UI --> WALK
    FOLD --> DEFAULT["Default constructors<br/>AccessibilityHierarchy tree"]
    FOLD --> CUSTOM["Your constructors<br/>Caller-defined node tree"]
    DEFAULT --> FLAT["flattenToElements<br/>Reading order from traversalIndex"]
    FOLD --> ELEMENT["Publicly read-only AccessibilityElement<br/>Captured facts + derived context"]
    ELEMENT --> SPEECH["On access: compute description and hint<br/>from stored values"]

    classDef public fill:#e8f1ff,stroke:#3973b9,color:#111;
    classDef capture fill:#fff0da,stroke:#c47b16,color:#111;
    class API,ELEMENT,SPEECH,DEFAULT,CUSTOM,FLAT public;
    class WALK capture;
```

| Private type | What it carries |
|---|---|
| `CapturedElement` | Public `AccessibilityElement` value, original strong source, sorting frame, raw rotor captures, view flag, traversal index |
| `ContainerInfo` | Public `AccessibilityContainer` payload, original strong source, role, navigation/context rules, tab/table facts |
| `CapturedDataTable` | Call-scoped reference record retaining the live table source and parent-table link; accumulates captured cell relationships and a header cache as sources are encountered |
| `AccessibilityNode` | Either a captured leaf or a group of child nodes, with explicit-order and group-anchor information |

On entry to a container candidate, the walk captures its own candidate public `AccessibilityContainer` metadata, geometry, and policies before selecting or visiting children. Ancestor container getters therefore run before descendant capture. On exit, group completion uses only captured data to determine whether accessible descendants exist, whether to emit a container, and any child-inferred role.

Leaf public values, geometry, and raw rotor targets are captured when their sources are encountered. Table cell and header relationship queries are recorded as sources are discovered during the live walk; context and header child indices are resolved later from captured facts and the ordered tree. Sorting and rotor formatting also use captured data. All live reads finish before the generic fold invokes caller constructors.

The caller should settle layout before parsing; the sequential walk captures values as it proceeds rather than making an atomic UIKit snapshot. Later source mutations, including getter-driven mutations, do not update fields or geometry already captured.

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

    subgraph CONSTRUCTION["Children-first construction order"]
        C1["makeElement A1"]
        C2["makeElement A2"]
        C3["makeContainer A<br/>children: A1, A2"]
        C4["makeElement B"]

        C1 --> C2 --> C3 --> C4
    end
```

The structural and navigation projections share the same `CapturedElement` instances. Attaching context to the stored value or assigning an index updates the occurrence that both projections refer to. Repeated appearances of one live source have separate records and can receive different context and indices.

Constructor invocation order follows the structural fold. Consumers use the supplied traversal indices when they need reading order.

## 3. Building the public result

Public `AccessibilityElement` and `AccessibilityContainer` values are the parser's payload storage. The private records add source associations and bookkeeping needed to derive order and context. The model's `Parsing` SPI provides `addContext(_:)` and `addCustomRotors(_:)`; ordinary callers see read-only properties.

```mermaid
flowchart TD
    CAPTURE["Entry: capture candidate AccessibilityContainer facts and policies<br/>Walk: capture AccessibilityElement, geometry, rotors and table relationships<br/>Exit: complete groups using captured data"]
    PREPARE["Derive reading order and context<br/>Assign traversalIndex and attach context<br/>Resolve table header child indices"]
    ROTORS["Format captured rotor targets with context<br/>Attach portable rotor results"]
    RECORD["Completed public payloads<br/>inside private working records"]
    SOURCE["Retained original source objects"]

    subgraph FOLD["Generic fold into caller-defined Node"]
        LEAF["makeElement<br/>AccessibilityElement + traversalIndex + live source"]
        CONTAINER["makeContainer<br/>AccessibilityContainer + completed child nodes + live source"]
        LEAF -->|"Completed child nodes"| CONTAINER
    end

    CAPTURE --> PREPARE --> ROTORS --> RECORD
    RECORD --> LEAF
    RECORD --> CONTAINER
    SOURCE -.->|"Leaf source argument"| LEAF
    SOURCE -.->|"Container source argument"| CONTAINER
    LEAF --> OUTPUT["Caller-defined node tree"]
    CONTAINER --> OUTPUT
    RECORD --> SPEECH["Element description and hint computed from stored values"]
```

The fold passes the completed public values directly. It performs no source reads or payload reconstruction, so caller mutations do not affect later delivered values. Private groups that preserve array slots without an emitted container pass their completed children through.

The caller-supplied generic constructors retain their signatures:

```swift
makeElement: (AccessibilityElement, Int, NSObject) -> Node
makeContainer: (AccessibilityContainer, [Node], NSObject) -> Node
```

### Source ownership

The parser holds strong references to the original live sources during its synchronous call and passes those exact objects to the caller's constructors. All working records are local to the call; the parser keeps no source references after returning. UIKit or caller-owned objects may still retain the sources, so this does not guarantee their deallocation.

The library-supplied constructors ignore the sources; the returned `AccessibilityHierarchy` contains captured values only.

Custom constructors control their own ownership. Storing a source strongly in a returned node or elsewhere keeps it alive beyond parsing and can retain its UI hierarchy. An ownership cycle can leak those objects. Use weak references for source associations that should not extend the UI object's lifetime. The captured public values remain usable independently of the live sources.
