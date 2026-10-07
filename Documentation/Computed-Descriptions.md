# Computed element descriptions

The parser captures an element's label, value, traits, raw hint, and language, then derives its container context. `AccessibilityElement.description` and `hint` format those stored values when read. Formatting uses the existing speech rules and translations and does not query the source UIKit object.

On entry to a container candidate, the parser captures its own candidate public metadata, geometry, and policies before selecting or visiting children. Ancestor container getters run before descendant capture. Group completion on exit uses only captured data to determine descendant presence, container emission, and any child-inferred role.

Public element values and raw rotor targets are captured when their sources are encountered. Table cell and header relationship queries are recorded as sources are discovered during the live walk; context and header child indices are resolved later. The parser attaches context through `addContext(_:)` and formats rotor results from captured values.

All live reads finish before the generic fold passes completed public elements and containers to the caller-supplied constructors with their exact original live sources. Changing a source in a constructor does not change that element or elements delivered by later constructors.

Capture is sequential. Settle layout before parsing; later getter-driven mutations do not update fields or geometry already captured.

## Constructing elements

Remove the `description:` initializer argument. The `hint:` argument takes the captured accessibility hint before any trait instructions are added. The element stores that input privately and computes separate `description` and `hint` outputs, including container position, table headers, and trait instructions.

Delivered elements, containers, geometry, custom content, and rotor results are publicly read-only; derived properties are getter-only. The model exposes `addContext(_:)` and `addCustomRotors(_:)` through the `Parsing` SPI so the parser can complete its stored public payloads without rereading captured fields. Ordinary callers cannot mutate context or rotors. Parse the hierarchy again to capture changed relationships and produce new elements with updated context.

`CustomRotor.Result` and `CustomRotor.results` replace `ResultMarker` and `resultMarkers`. Rotor names, results, and custom-content fields are now read-only. The rotor result array retains its existing `resultMarkers` JSON key so saved rotor data still decodes.

## Saved payloads

New payloads store `authoredHint`, including an explicit `null` when absent, and omit the computed `description` and `hint`. Speech is regenerated when a decoded element's properties are read.

Older payloads still decode. Their stored description is ignored; the old hint is used as best-effort raw input when `authoredHint` is absent. Those payloads did not retain the original hint or container context, so their original speech cannot always be reconstructed exactly. For example, an already-formatted adjustable hint can gain a second adjustment instruction. Newly captured payloads preserve the raw inputs and round-trip without that loss.

Formatting uses the stored accessibility language, or the current default locale when no language was captured. The existing iOS 17 switch-value rule is evaluated on the host running the formatter.
