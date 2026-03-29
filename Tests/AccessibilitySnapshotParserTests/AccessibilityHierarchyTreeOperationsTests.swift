#if canImport(UIKit)
    @testable import AccessibilitySnapshotParser
    import XCTest

    final class AccessibilityHierarchyTreeOperationsTests: XCTestCase {
        // MARK: - Fixtures

        private func el(
            label: String,
            value: String? = nil,
            traits: UIAccessibilityTraits = .none,
            index: Int = 0
        ) -> AccessibilityHierarchy {
            .element(
                AccessibilityElement(
                    description: label,
                    label: label,
                    value: value,
                    traits: traits,
                    identifier: nil,
                    hint: nil,
                    userInputLabels: nil,
                    shape: .frame(.zero),
                    activationPoint: .zero,
                    usesDefaultActivationPoint: true,
                    customActions: [],
                    customContent: [],
                    customRotors: [],
                    accessibilityLanguage: nil,
                    respondsToUserInteraction: true
                ),
                traversalIndex: index
            )
        }

        private func group(
            label: String? = nil,
            children: [AccessibilityHierarchy]
        ) -> AccessibilityHierarchy {
            .container(
                AccessibilityContainer(
                    type: .semanticGroup(label: label, value: nil, identifier: nil),
                    frame: .zero
                ),
                children: children
            )
        }

        private func dataTable(
            children: [AccessibilityHierarchy]
        ) -> AccessibilityHierarchy {
            .container(
                AccessibilityContainer(
                    type: .dataTable(rowCount: 3, columnCount: 2),
                    frame: .zero
                ),
                children: children
            )
        }

        private func tabBar(
            children: [AccessibilityHierarchy]
        ) -> AccessibilityHierarchy {
            .container(
                AccessibilityContainer(type: .tabBar, frame: .zero),
                children: children
            )
        }

        /// Extract label from an element node.
        private func label(of node: AccessibilityHierarchy) -> String? {
            if case let .element(e, _) = node { return e.label }
            return nil
        }

        // =========================================================================

        // MARK: - Filter: Element

        // =========================================================================

        func testFilterKeepsMatchingElement() {
            let node = el(label: "Save")
            let result = node.filtered { n in
                if case let .element(e, _) = n { return e.label == "Save" }
                return false
            }
            XCTAssertNotNil(result)
        }

        func testFilterRemovesNonMatchingElement() {
            let node = el(label: "Cancel")
            let result = node.filtered { n in
                if case let .element(e, _) = n { return e.label == "Save" }
                return false
            }
            XCTAssertNil(result)
        }

        func testFilterPreservesTraversalIndex() {
            let node = el(label: "X", index: 42)
            let result = node.filtered { _ in true }
            if case let .element(_, idx) = result {
                XCTAssertEqual(idx, 42)
            } else {
                XCTFail("Expected element")
            }
        }

        // =========================================================================

        // MARK: - Filter: Container

        // =========================================================================

        func testContainerKeptWhenChildMatches() {
            let tree = group(label: "Toolbar", children: [
                el(label: "Save", index: 0),
                el(label: "Cancel", index: 1),
            ])

            let result = tree.filtered { n in
                if case let .element(e, _) = n { return e.label == "Save" }
                return false
            }

            guard case let .container(_, children) = result else {
                return XCTFail("Expected container")
            }
            XCTAssertEqual(children.count, 1)
            XCTAssertEqual(label(of: children[0]), "Save")
        }

        func testContainerRemovedWhenNoChildMatches() {
            let tree = group(label: "Toolbar", children: [
                el(label: "Cancel", index: 0),
                el(label: "Delete", index: 1),
            ])

            let result = tree.filtered { n in
                if case let .element(e, _) = n { return e.label == "Save" }
                return false
            }
            XCTAssertNil(result)
        }

        func testEmptyContainerKeptWhenPredicateMatchesContainer() {
            let tree = dataTable(children: [
                el(label: "Item"),
            ])

            let result = tree.filtered { n in
                if case let .container(c, _) = n {
                    if case .dataTable = c.type { return true }
                }
                return false
            }

            guard case let .container(c, children) = result else {
                return XCTFail("Expected container")
            }
            if case .dataTable = c.type {} else {
                XCTFail("Expected dataTable container type")
            }
            XCTAssertEqual(children.count, 0)
        }

        func testContainerPreservesMetadata() {
            let tree = group(label: "Settings", children: [
                el(label: "Volume", index: 0),
            ])

            let result = tree.filtered { _ in true }
            guard case let .container(c, _) = result else {
                return XCTFail("Expected container")
            }
            if case let .semanticGroup(lbl, _, _) = c.type {
                XCTAssertEqual(lbl, "Settings")
            } else {
                XCTFail("Expected semanticGroup")
            }
        }

        // =========================================================================

        // MARK: - Filter: Nested

        // =========================================================================

        func testDeepNestedElementSurvives() {
            let tree = group(label: "Root", children: [
                group(label: "Section A", children: [
                    el(label: "Nope", index: 0),
                ]),
                group(label: "Section B", children: [
                    group(label: "Subsection", children: [
                        el(label: "Target", index: 1),
                    ]),
                ]),
            ])

            let result = tree.filtered { n in
                if case let .element(e, _) = n { return e.label == "Target" }
                return false
            }

            guard case let .container(_, rootChildren) = result else {
                return XCTFail("Expected root container")
            }
            XCTAssertEqual(rootChildren.count, 1, "Section A should be pruned")

            guard case let .container(_, sectionBChildren) = rootChildren[0] else {
                return XCTFail("Expected Section B")
            }
            guard case let .container(_, subChildren) = sectionBChildren[0] else {
                return XCTFail("Expected Subsection")
            }
            XCTAssertEqual(label(of: subChildren[0]), "Target")
        }

        func testMultipleMatchesAcrossBranches() {
            let tree = group(children: [
                group(children: [el(label: "A", traits: .button, index: 0)]),
                group(children: [el(label: "B", index: 1)]),
                group(children: [el(label: "C", traits: .button, index: 2)]),
            ])

            let result = tree.filtered { n in
                if case let .element(e, _) = n { return e.traits.contains(.button) }
                return false
            }

            guard case let .container(_, children) = result else {
                return XCTFail("Expected container")
            }
            XCTAssertEqual(children.count, 2, "Middle branch (no buttons) should be pruned")
        }

        // =========================================================================

        // MARK: - Filter: Trait & Container Type

        // =========================================================================

        func testFilterByTrait() {
            let tree = group(children: [
                el(label: "Title", traits: .header, index: 0),
                el(label: "Body", index: 1),
                el(label: "Subtitle", traits: .header, index: 2),
            ])

            let result = tree.filtered { n in
                if case let .element(e, _) = n { return e.traits.contains(.header) }
                return false
            }

            guard case let .container(_, children) = result else {
                return XCTFail("Expected container")
            }
            XCTAssertEqual(children.count, 2)
        }

        func testFilterForContainerType() {
            let tree = group(children: [
                dataTable(children: [el(label: "Row 1", index: 0)]),
                tabBar(children: [el(label: "Home", index: 1)]),
                group(children: [el(label: "Other", index: 2)]),
            ])

            // Keep all elements and dataTable containers
            let result = tree.filtered { n in
                if case let .container(c, _) = n {
                    if case .dataTable = c.type { return true }
                }
                if case .element = n { return true }
                return false
            }

            guard case let .container(_, children) = result else {
                return XCTFail("Expected root container")
            }
            // All three survive: dataTable matches directly + has element children,
            // tabBar and group survive because their element children match
            XCTAssertEqual(children.count, 3)
        }

        // =========================================================================

        // MARK: - Filter: Array

        // =========================================================================

        func testFilteredHierarchyOnArray() {
            let roots: [AccessibilityHierarchy] = [
                el(label: "A", index: 0),
                el(label: "B", index: 1),
                el(label: "C", index: 2),
            ]

            let result = roots.filteredHierarchy { n in
                if case let .element(e, _) = n { return e.label != "B" }
                return false
            }
            XCTAssertEqual(result.count, 2)
        }

        func testFilteredHierarchyPrunesEmptyContainers() {
            let roots: [AccessibilityHierarchy] = [
                group(label: "Has Match", children: [el(label: "Keep")]),
                group(label: "No Match", children: [el(label: "Drop")]),
            ]

            let result = roots.filteredHierarchy { n in
                if case let .element(e, _) = n { return e.label == "Keep" }
                return false
            }
            XCTAssertEqual(result.count, 1)
        }

        // =========================================================================

        // MARK: - Filter: Edge Cases

        // =========================================================================

        func testFilterOnEmptyArray() {
            let roots: [AccessibilityHierarchy] = []
            let result = roots.filteredHierarchy { _ in true }
            XCTAssertTrue(result.isEmpty)
        }

        func testAlwaysTruePreservesTree() {
            let tree = group(label: "Root", children: [
                el(label: "A", index: 0),
                group(label: "Inner", children: [
                    el(label: "B", index: 1),
                ]),
            ])
            XCTAssertEqual(tree.filtered { _ in true }, tree)
        }

        func testAlwaysFalseReturnsNil() {
            let tree = group(children: [el(label: "A")])
            XCTAssertNil(tree.filtered { _ in false })
        }

        func testFilterEmptyContainer() {
            let tree = group(label: "Empty", children: [])
            // No children, container doesn't match → nil
            XCTAssertNil(tree.filtered { _ in false })
            // Container matches predicate → kept empty
            let kept = tree.filtered { _ in true }
            XCTAssertNotNil(kept)
            if case let .container(_, children) = kept {
                XCTAssertTrue(children.isEmpty)
            }
        }

        // =========================================================================

        // MARK: - Map: Element

        // =========================================================================

        func testMapTransformsElementLabel() {
            let node = el(label: "hello", index: 5)
            let result = node.mapped { n in
                guard case let .element(e, idx) = n else { return n }
                return .element(
                    AccessibilityElement(
                        description: e.description.uppercased(),
                        label: e.label?.uppercased(),
                        value: e.value,
                        traits: e.traits,
                        identifier: e.identifier,
                        hint: e.hint,
                        userInputLabels: e.userInputLabels,
                        shape: e.shape,
                        activationPoint: e.activationPoint,
                        usesDefaultActivationPoint: e.usesDefaultActivationPoint,
                        customActions: e.customActions,
                        customContent: e.customContent,
                        customRotors: e.customRotors,
                        accessibilityLanguage: e.accessibilityLanguage,
                        respondsToUserInteraction: e.respondsToUserInteraction
                    ),
                    traversalIndex: idx
                )
            }
            XCTAssertEqual(label(of: result), "HELLO")
            if case let .element(_, idx) = result {
                XCTAssertEqual(idx, 5, "Traversal index preserved")
            }
        }

        func testMapIdentityPreservesTree() {
            let tree = group(children: [
                el(label: "A", index: 0),
                group(children: [el(label: "B", index: 1)]),
            ])
            XCTAssertEqual(tree.mapped { $0 }, tree)
        }

        // =========================================================================

        // MARK: - Map: Container

        // =========================================================================

        func testMapTransformsContainerChildren() {
            let tree = group(children: [
                el(label: "A", index: 0),
                el(label: "B", index: 1),
            ])

            let result = tree.mapped { n in
                guard case let .element(e, idx) = n else { return n }
                return .element(
                    AccessibilityElement(
                        description: e.description,
                        label: (e.label ?? "") + "!",
                        value: e.value,
                        traits: e.traits,
                        identifier: e.identifier,
                        hint: e.hint,
                        userInputLabels: e.userInputLabels,
                        shape: e.shape,
                        activationPoint: e.activationPoint,
                        usesDefaultActivationPoint: e.usesDefaultActivationPoint,
                        customActions: e.customActions,
                        customContent: e.customContent,
                        customRotors: e.customRotors,
                        accessibilityLanguage: e.accessibilityLanguage,
                        respondsToUserInteraction: e.respondsToUserInteraction
                    ),
                    traversalIndex: idx
                )
            }

            guard case let .container(_, children) = result else {
                return XCTFail("Expected container")
            }
            XCTAssertEqual(label(of: children[0]), "A!")
            XCTAssertEqual(label(of: children[1]), "B!")
        }

        func testMapIsBottomUp() {
            var visitOrder: [String] = []

            let tree = group(label: "Root", children: [
                el(label: "Child", index: 0),
            ])

            _ = tree.mapped { n in
                switch n {
                case let .element(e, _):
                    visitOrder.append(e.label ?? "?")
                case let .container(c, _):
                    if case let .semanticGroup(lbl, _, _) = c.type {
                        visitOrder.append(lbl ?? "?")
                    }
                }
                return n
            }

            XCTAssertEqual(visitOrder, ["Child", "Root"], "Children visited before parent")
        }

        func testMapDeepNesting() {
            let tree = group(children: [
                group(children: [
                    group(children: [
                        el(label: "deep", index: 0),
                    ]),
                ]),
            ])

            let result = tree.mapped { n in
                guard case let .element(e, idx) = n else { return n }
                return .element(
                    AccessibilityElement(
                        description: e.description,
                        label: "found",
                        value: e.value,
                        traits: e.traits,
                        identifier: e.identifier,
                        hint: e.hint,
                        userInputLabels: e.userInputLabels,
                        shape: e.shape,
                        activationPoint: e.activationPoint,
                        usesDefaultActivationPoint: e.usesDefaultActivationPoint,
                        customActions: e.customActions,
                        customContent: e.customContent,
                        customRotors: e.customRotors,
                        accessibilityLanguage: e.accessibilityLanguage,
                        respondsToUserInteraction: e.respondsToUserInteraction
                    ),
                    traversalIndex: idx
                )
            }

            guard case let .container(_, l1) = result,
                  case let .container(_, l2) = l1[0],
                  case let .container(_, l3) = l2[0]
            else {
                return XCTFail("Expected nested containers")
            }
            XCTAssertEqual(label(of: l3[0]), "found")
        }

        func testMapCanReplaceContainerType() {
            let tree = group(label: "Nav", children: [
                el(label: "Home", index: 0),
            ])

            let result = tree.mapped { n in
                guard case let .container(_, children) = n else { return n }
                return .container(
                    AccessibilityContainer(type: .tabBar, frame: .zero),
                    children: children
                )
            }

            guard case let .container(c, children) = result else {
                return XCTFail("Expected container")
            }
            if case .tabBar = c.type {} else {
                XCTFail("Expected tabBar type")
            }
            XCTAssertEqual(children.count, 1)
        }

        func testMapCanCollapseContainerToElement() {
            let tree = group(children: [el(label: "Only", index: 7)])

            let result = tree.mapped { n in
                if case let .container(_, children) = n, children.count == 1 {
                    return children[0]
                }
                return n
            }

            XCTAssertEqual(label(of: result), "Only")
        }

        func testMapCanReindexTraversalOrder() {
            let roots: [AccessibilityHierarchy] = [
                el(label: "A", index: 0),
                el(label: "B", index: 1),
                el(label: "C", index: 2),
            ]

            var counter = 10
            let result = roots.mappedHierarchy { n in
                guard case let .element(e, _) = n else { return n }
                let newIndex = counter
                counter += 10
                return .element(e, traversalIndex: newIndex)
            }

            if case let .element(_, idx) = result[0] { XCTAssertEqual(idx, 10) }
            if case let .element(_, idx) = result[1] { XCTAssertEqual(idx, 20) }
            if case let .element(_, idx) = result[2] { XCTAssertEqual(idx, 30) }
        }

        // =========================================================================

        // MARK: - Map: Edge Cases & Array

        // =========================================================================

        func testMapEmptyContainer() {
            let tree = group(label: "Empty", children: [])
            let result = tree.mapped { $0 }
            XCTAssertEqual(result, tree)
        }

        func testMappedHierarchyOnArray() {
            let roots: [AccessibilityHierarchy] = [
                el(label: "a", index: 0),
                el(label: "b", index: 1),
            ]

            let result = roots.mappedHierarchy { n in
                guard case let .element(e, idx) = n else { return n }
                return .element(
                    AccessibilityElement(
                        description: e.description,
                        label: e.label?.uppercased(),
                        value: e.value,
                        traits: e.traits,
                        identifier: e.identifier,
                        hint: e.hint,
                        userInputLabels: e.userInputLabels,
                        shape: e.shape,
                        activationPoint: e.activationPoint,
                        usesDefaultActivationPoint: e.usesDefaultActivationPoint,
                        customActions: e.customActions,
                        customContent: e.customContent,
                        customRotors: e.customRotors,
                        accessibilityLanguage: e.accessibilityLanguage,
                        respondsToUserInteraction: e.respondsToUserInteraction
                    ),
                    traversalIndex: idx
                )
            }

            XCTAssertEqual(label(of: result[0]), "A")
            XCTAssertEqual(label(of: result[1]), "B")
        }

        func testMappedHierarchyEmptyArray() {
            let roots: [AccessibilityHierarchy] = []
            let result = roots.mappedHierarchy { $0 }
            XCTAssertTrue(result.isEmpty)
        }

        // =========================================================================

        // MARK: - Reduce: Count

        // =========================================================================

        func testReduceCountsElements() {
            let tree = group(children: [
                el(label: "A", index: 0),
                group(children: [
                    el(label: "B", index: 1),
                    el(label: "C", index: 2),
                ]),
            ])

            let count = tree.reduced(0) { acc, node in
                if case .element = node { return acc + 1 }
                return acc
            }
            XCTAssertEqual(count, 3)
        }

        func testReduceCountsContainers() {
            let tree = group(children: [
                group(children: [el(label: "A")]),
                group(children: []),
            ])

            let count = tree.reduced(0) { acc, node in
                if case .container = node { return acc + 1 }
                return acc
            }
            XCTAssertEqual(count, 3, "Root + 2 inner containers")
        }

        // =========================================================================

        // MARK: - Reduce: Collect

        // =========================================================================

        func testReduceCollectsLabels() {
            let tree = group(children: [
                el(label: "A", index: 0),
                el(label: "B", index: 1),
                group(children: [
                    el(label: "C", index: 2),
                ]),
            ])

            let labels = tree.reduced([String]()) { acc, node in
                if case let .element(e, _) = node, let lbl = e.label {
                    return acc + [lbl]
                }
                return acc
            }
            XCTAssertEqual(labels, ["A", "B", "C"])
        }

        func testReducePreOrderVisitOrder() {
            let tree = group(label: "R", children: [
                el(label: "1", index: 0),
                group(label: "G", children: [
                    el(label: "2", index: 1),
                ]),
            ])

            var order: [String] = []
            tree.reduced(()) { _, node in
                switch node {
                case let .element(e, _):
                    order.append(e.label ?? "?")
                case let .container(c, _):
                    if case let .semanticGroup(lbl, _, _) = c.type {
                        order.append(lbl ?? "?")
                    }
                }
            }
            XCTAssertEqual(order, ["R", "1", "G", "2"])
        }

        // =========================================================================

        // MARK: - Reduce: Numeric

        // =========================================================================

        func testReduceComputesMaxTraversalIndex() {
            let tree = group(children: [
                el(label: "A", index: 3),
                group(children: [
                    el(label: "B", index: 7),
                    el(label: "C", index: 1),
                ]),
            ])

            let maxIndex = tree.reduced(Int.min) { acc, node in
                if case let .element(_, idx) = node { return max(acc, idx) }
                return acc
            }
            XCTAssertEqual(maxIndex, 7)
        }

        // =========================================================================

        // MARK: - Reduce: Boolean

        // =========================================================================

        func testReduceChecksAnyButton() {
            let tree = group(children: [
                el(label: "Title", traits: .header),
                el(label: "OK", traits: .button),
            ])

            let hasButton = tree.reduced(false) { acc, node in
                if acc { return true }
                if case let .element(e, _) = node { return e.traits.contains(.button) }
                return false
            }
            XCTAssertTrue(hasButton)
        }

        func testReduceChecksAllInteractive() {
            let tree = group(children: [
                el(label: "A"),
                el(label: "B"),
            ])

            let allInteractive = tree.reduced(true) { acc, node in
                if !acc { return false }
                if case let .element(e, _) = node { return e.respondsToUserInteraction }
                return acc
            }
            XCTAssertTrue(allInteractive)
        }

        // =========================================================================

        // MARK: - Reduce: Edge Cases & Array

        // =========================================================================

        func testReduceOnSingleElement() {
            let node = el(label: "Solo", index: 0)
            let count = node.reduced(0) { acc, _ in acc + 1 }
            XCTAssertEqual(count, 1)
        }

        func testReduceEmptyContainer() {
            let tree = group(children: [])
            let count = tree.reduced(0) { acc, _ in acc + 1 }
            XCTAssertEqual(count, 1, "Just the container itself")
        }

        func testReducedHierarchyOnArray() {
            let roots: [AccessibilityHierarchy] = [
                el(label: "A", index: 0),
                group(children: [
                    el(label: "B", index: 1),
                ]),
            ]

            let count = roots.reducedHierarchy(0) { acc, node in
                if case .element = node { return acc + 1 }
                return acc
            }
            XCTAssertEqual(count, 2)
        }

        func testReducedHierarchyEmptyArray() {
            let roots: [AccessibilityHierarchy] = []
            let count = roots.reducedHierarchy(0) { acc, _ in acc + 1 }
            XCTAssertEqual(count, 0)
        }

        func testReducedHierarchyVisitsAllRoots() {
            let roots: [AccessibilityHierarchy] = [
                group(children: [el(label: "A")]),
                group(children: [el(label: "B")]),
                group(children: [el(label: "C")]),
            ]

            let labels = roots.reducedHierarchy([String]()) { acc, node in
                if case let .element(e, _) = node, let lbl = e.label {
                    return acc + [lbl]
                }
                return acc
            }
            XCTAssertEqual(labels, ["A", "B", "C"])
        }

        // =========================================================================

        // MARK: - Rewrite Validation

        // =========================================================================

        /// Proves forEach visits in same order as reduced.
        func testForEachMatchesReduceOrder() {
            let tree = group(label: "R", children: [
                el(label: "1", index: 0),
                group(label: "G", children: [
                    el(label: "2", index: 1),
                    el(label: "3", index: 2),
                ]),
            ])

            var forEachOrder: [String] = []
            tree.forEach { node in
                if case let .element(e, _) = node {
                    forEachOrder.append(e.label ?? "?")
                }
            }

            let reducedOrder = tree.reduced([String]()) { acc, node in
                if case let .element(e, _) = node, let lbl = e.label {
                    return acc + [lbl]
                }
                return acc
            }

            XCTAssertEqual(forEachOrder, reducedOrder)
        }

        /// Proves sortIndex equals reduce-based minimum traversal index.
        func testSortIndexMatchesReduceMin() {
            let tree = group(children: [
                el(label: "A", index: 5),
                group(children: [
                    el(label: "B", index: 2),
                    el(label: "C", index: 8),
                ]),
            ])

            let reduceMin = tree.reduced(Int.max) { acc, node in
                guard case let .element(_, index) = node else { return acc }
                return min(acc, index)
            }

            XCTAssertEqual(tree.sortIndex, reduceMin)
            XCTAssertEqual(tree.sortIndex, 2)
        }

        /// Proves flattenToElements matches a reduce-based collect + sort.
        func testFlattenToElementsMatchesReduce() {
            let roots: [AccessibilityHierarchy] = [
                group(children: [
                    el(label: "C", index: 2),
                    el(label: "A", index: 0),
                ]),
                group(children: [
                    el(label: "B", index: 1),
                ]),
            ]

            let fromFlatten = roots.flattenToElements().map { $0.label }

            let fromReduce = roots
                .reducedHierarchy([(index: Int, label: String?)]()) { acc, node in
                    guard case let .element(e, idx) = node else { return acc }
                    return acc + [(idx, e.label)]
                }
                .sorted { $0.index < $1.index }
                .map { $0.label }

            XCTAssertEqual(fromFlatten, fromReduce)
            XCTAssertEqual(fromFlatten, ["A", "B", "C"])
        }

        /// Proves flattenToContainers matches a reduce-based collect.
        func testFlattenToContainersMatchesReduce() {
            let roots: [AccessibilityHierarchy] = [
                group(label: "Outer", children: [
                    dataTable(children: [el(label: "X")]),
                    tabBar(children: [el(label: "Y")]),
                ]),
            ]

            let fromFlatten = roots.flattenToContainers()

            let fromReduce = roots.reducedHierarchy([AccessibilityContainer]()) { acc, node in
                guard case let .container(container, _) = node else { return acc }
                return acc + [container]
            }

            XCTAssertEqual(fromFlatten.count, fromReduce.count)
            XCTAssertEqual(fromFlatten.count, 3, "Outer + dataTable + tabBar")
            // Verify same order (depth-first: outer, dataTable, tabBar)
            for (a, b) in zip(fromFlatten, fromReduce) {
                XCTAssertEqual(a, b)
            }
        }

        // =========================================================================

        // MARK: - Composition: Filter + Map

        // =========================================================================

        func testFilterThenMap() {
            let tree = group(children: [
                el(label: "Keep", traits: .button, index: 0),
                el(label: "Drop", index: 1),
                el(label: "Also Keep", traits: .button, index: 2),
            ])

            let result = tree
                .filtered { n in
                    if case let .element(e, _) = n { return e.traits.contains(.button) }
                    return true
                }?
                .mapped { n in
                    guard case let .element(e, idx) = n else { return n }
                    return .element(
                        AccessibilityElement(
                            description: e.description,
                            label: e.label?.uppercased(),
                            value: e.value,
                            traits: e.traits,
                            identifier: e.identifier,
                            hint: e.hint,
                            userInputLabels: e.userInputLabels,
                            shape: e.shape,
                            activationPoint: e.activationPoint,
                            usesDefaultActivationPoint: e.usesDefaultActivationPoint,
                            customActions: e.customActions,
                            customContent: e.customContent,
                            customRotors: e.customRotors,
                            accessibilityLanguage: e.accessibilityLanguage,
                            respondsToUserInteraction: e.respondsToUserInteraction
                        ),
                        traversalIndex: idx
                    )
                }

            guard case let .container(_, children) = result else {
                return XCTFail("Expected container")
            }
            XCTAssertEqual(children.count, 2)
            XCTAssertEqual(label(of: children[0]), "KEEP")
            XCTAssertEqual(label(of: children[1]), "ALSO KEEP")
        }

        // =========================================================================

        // MARK: - Composition: Filter + Reduce

        // =========================================================================

        func testFilterThenReduce() {
            let tree = group(children: [
                el(label: "Header", traits: .header, index: 0),
                el(label: "Body", index: 1),
                el(label: "Footer", traits: .header, index: 2),
            ])

            let headerLabels = tree
                .filtered { n in
                    if case let .element(e, _) = n { return e.traits.contains(.header) }
                    return true
                }?
                .reduced([String]()) { acc, node in
                    if case let .element(e, _) = node, let lbl = e.label {
                        return acc + [lbl]
                    }
                    return acc
                }

            XCTAssertEqual(headerLabels, ["Header", "Footer"])
        }

        // =========================================================================

        // MARK: - Composition: Map + Reduce

        // =========================================================================

        func testMapThenReduce() {
            let tree = group(children: [
                el(label: "a", index: 0),
                el(label: "b", index: 1),
            ])

            let uppercased = tree
                .mapped { n in
                    guard case let .element(e, idx) = n else { return n }
                    return .element(
                        AccessibilityElement(
                            description: e.description,
                            label: e.label?.uppercased(),
                            value: e.value,
                            traits: e.traits,
                            identifier: e.identifier,
                            hint: e.hint,
                            userInputLabels: e.userInputLabels,
                            shape: e.shape,
                            activationPoint: e.activationPoint,
                            usesDefaultActivationPoint: e.usesDefaultActivationPoint,
                            customActions: e.customActions,
                            customContent: e.customContent,
                            customRotors: e.customRotors,
                            accessibilityLanguage: e.accessibilityLanguage,
                            respondsToUserInteraction: e.respondsToUserInteraction
                        ),
                        traversalIndex: idx
                    )
                }
                .reduced("") { acc, node in
                    if case let .element(e, _) = node, let lbl = e.label {
                        return acc.isEmpty ? lbl : acc + "," + lbl
                    }
                    return acc
                }

            XCTAssertEqual(uppercased, "A,B")
        }

        // =========================================================================

        // MARK: - Composition: All Three

        // =========================================================================

        func testFilterMapReduce() {
            let tree = group(children: [
                el(label: "Settings", traits: .button, index: 0),
                el(label: "Info", index: 1),
                el(label: "Profile", traits: .button, index: 2),
                el(label: "Help", index: 3),
            ])

            let result = tree
                .filtered { n in
                    if case let .element(e, _) = n { return e.traits.contains(.button) }
                    return true
                }?
                .mapped { n in
                    guard case let .element(e, idx) = n else { return n }
                    return .element(
                        AccessibilityElement(
                            description: e.description,
                            label: "[" + (e.label ?? "") + "]",
                            value: e.value,
                            traits: e.traits,
                            identifier: e.identifier,
                            hint: e.hint,
                            userInputLabels: e.userInputLabels,
                            shape: e.shape,
                            activationPoint: e.activationPoint,
                            usesDefaultActivationPoint: e.usesDefaultActivationPoint,
                            customActions: e.customActions,
                            customContent: e.customContent,
                            customRotors: e.customRotors,
                            accessibilityLanguage: e.accessibilityLanguage,
                            respondsToUserInteraction: e.respondsToUserInteraction
                        ),
                        traversalIndex: idx
                    )
                }
                .reduced(0) { acc, node in
                    if case .element = node { return acc + 1 }
                    return acc
                }

            XCTAssertEqual(result, 2)
        }
    }
#endif
