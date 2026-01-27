import 'package:flutter/widgets.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/directive_node.dart';

/// A function that builds a widget for a generic directive.
typedef DirectiveBuilder =
    WidgetSpan Function(BuildContext context, InlineDirectiveNode node);
