# Computed element descriptions

The parser captures an element's label, value, traits, raw hint, language, and container context. `AccessibilityElement.description` and `hint` format those captured values when read. Formatting uses the existing speech rules and translations and does not query the source UIKit object.

The caller-supplied generic constructors still receive the live source object. Element fields are captured after the structural walk, and context-dependent rotor results are collected before any caller constructor runs. The generic fold constructs each public element from its completed private record. Changing a source in a constructor does not change that element or elements delivered by later constructors.

## Constructing elements

Remove the `description:` initializer argument. The `hint:` argument takes the captured accessibility hint before any trait instructions are added. The element stores that input privately and computes separate `description` and `hint` outputs, including container position, table headers, and trait instructions.

`withDescription(_:hint:)` is removed. Delivered elements, containers, geometry, custom content, and rotor results are publicly read-only; derived properties are getter-only. The model exposes `addContext(_:)` through the `Parsing` SPI so the parser can attach derived context without rereading captured fields. Ordinary callers cannot mutate context. Parse the hierarchy again to capture changed relationships and produce new elements with updated context. The parser's intermediate capture state remains mutable while it prepares the result.

`CustomRotor.Result` and `CustomRotor.results` replace `ResultMarker` and `resultMarkers`. Rotor names, results, and custom-content fields are now read-only. The rotor result array retains its existing `resultMarkers` JSON key so saved rotor data still decodes.

## Saved payloads

New payloads store `authoredHint`, including an explicit `null` when absent, and omit the computed `description` and `hint`. Speech is regenerated when a decoded element's properties are read.

Older payloads still decode. Their stored description is ignored; the old hint is used as best-effort raw input when `authoredHint` is absent. Those payloads did not retain the original hint or container context, so their original speech cannot always be reconstructed exactly. For example, an already-formatted adjustable hint can gain a second adjustment instruction. Newly captured payloads preserve the raw inputs and round-trip without that loss.

Formatting uses the stored accessibility language, or the current default locale when no language was captured. The existing iOS 17 switch-value rule is evaluated on the host running the formatter.
