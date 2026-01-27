Context: We are building a collaborative markdown editor. We need to extend the markdown parser to support Generic Inline Directives (specifically "Text Directives"). This is required to support a new "Relationships" feature in the consuming app (resonant-bohr), where users will type :child[123-id] to link commitments.

Goal: Implement support for parsing and rendering Text Directives in the blazing_protostar package.

Specification:

Syntax: Implement the CommonMark Generic Directive extension syntax for Text Directives:
Format: :name[content]
Example: :child[123-abc-456]
Constraint: For this MVP, we strictly care about the :name[content] form. We do not need to support arguments 
(args)
 or attributes {attrs} yet, but the parser should be robust enough to strictly match the directive pattern so we can expand later.
Parsing Logic:
Add/Update the markdown parser to recognize the colon prefix syntax.
Ensure it does not collide with standard text usage (e.g. Time: 12:00 should not trigger it, but :tag[text] should).
Extract name (e.g. "child") and content (e.g. "123-abc-456").
Rendering/Builder:
Update the MarkdownText / MarkdownEditor widget (or equivalent builder architecture) to allow consumers to provide a custom builder for these directives.
Example Usage: The consumer should be able to say: "When you see directive child, render a Chip with text 123-abc-456".

Deliverables:
Updated parser logic to handle :name[content].
Tests verifying :child[123] parses correctly and standard text is unaffected.
(If applicable) A way to register custom builders for specific directive names.

Critical:
- find test cases for the generic directive extension and incorporate them into our test suite. You can add the specs next to test/assets/spec_tests.json
- 