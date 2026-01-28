**Goal**: Enable developers to register custom renderers for markdown. This will be used to support custom directives (":") and other custom markdown elements. 

The existing rendering for standard commonmark should be customizable. By default it should behave as it does now, but developers should be able to register custom renderers for specific markdown elements if desired (eg. custom image rendering, custom link handling, etc.)

**Analysis**:
- `MarkdownTextEditingController` already supports `directiveBuilders`.
- `MarkdownParser` already supports standard directive syntax (e.g. `:child[id]`).
- **Missing**: The `InlineDirectiveNode` class and `DirectiveBuilder` typedef are not exported, making the API unusable.

