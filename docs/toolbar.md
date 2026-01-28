# Toolbar Customization

The `MarkdownToolbar` is designed to be flexible. The `MarkdownEditor` widget includes a default toolbar automatically, but you can customize it in several ways.

## 1. Default Usage

By default, `MarkdownEditor` includes a toolbar with no additional configuration needed:

```dart
MarkdownEditor(controller: controller)
```

## 2. Custom Toolbar via Builder

To customize the buttons in the toolbar, use the `toolbarBuilder` parameter. This gives you access to the toolbar building blocks to compose your own layout:

### Available Components

- **`MarkdownStyleButton`**: Smart button that toggles a style (bold, italic, list, link) based on cursor position
- **`MarkdownHeadingDropdown`**: Dropdown for selecting heading levels (Normal, H1-H6)
- **`MarkdownWysiwygToggleButton`**: Toggles between Raw and WYSIWYG modes

### Example

```dart
MarkdownEditor(
  controller: controller,
  toolbarBuilder: (context, controller, isWysiwygMode, onWysiwygToggle) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          MarkdownStyleButton(
            controller: controller,
            style: 'bold',
            icon: Icons.format_bold,
            tooltip: 'Bold',
          ),
          MarkdownStyleButton(
            controller: controller,
            style: 'italic',
            icon: Icons.format_italic,
            tooltip: 'Italic',
          ),
          MarkdownHeadingDropdown(controller: controller),
          // Your custom button
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () => controller.insertAtCursor(':star[Favorite]'),
            tooltip: 'Add Star Directive',
          ),
          const Spacer(),
          MarkdownWysiwygToggleButton(
            isWysiwygMode: isWysiwygMode,
            onPressed: onWysiwygToggle,
          ),
        ],
      ),
    );
  },
)
```

## 3. Inheritance (Subclassing MarkdownToolbar)

If you want to keep the standard toolbar look and feel but change the buttons, you can subclass `MarkdownToolbar` and override `buildToolbarButtons`:

```dart
class MyCustomToolbar extends MarkdownToolbar {
  const MyCustomToolbar({
    super.key,
    required super.controller,
    super.isWysiwygMode,
    super.onWysiwygToggle,
  });

  @override
  List<Widget> buildToolbarButtons(BuildContext context) {
    return [
      MarkdownStyleButton(
        controller: controller,
        style: 'bold',
        icon: Icons.format_bold,
        tooltip: 'Bold',
      ),
      IconButton(
        icon: const Icon(Icons.add_box),
        onPressed: () => controller.insertAtCursor(':callout[Info]'),
        tooltip: 'Add Callout',
      ),
    ];
  }
}
```

Then use it with `MarkdownEditor`:

```dart
MarkdownEditor(
  controller: controller,
  toolbarBuilder: (context, controller, isWysiwygMode, onWysiwygToggle) {
    return MyCustomToolbar(
      controller: controller,
      isWysiwygMode: isWysiwygMode,
      onWysiwygToggle: onWysiwygToggle,
    );
  },
)
```
