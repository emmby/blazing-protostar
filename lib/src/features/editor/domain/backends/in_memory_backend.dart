import 'document_backend.dart';

/// A simple in-memory implementation of [DocumentBackend].
///
/// This is the default backend for non-collaborative sessions.
class InMemoryBackend extends DocumentBackend {
  String _text;

  InMemoryBackend({String initialText = ''}) : _text = initialText;

  @override
  String get text => _text;

  @override
  void updateText(String newText) {
    if (_text == newText) return;
    _text = newText;
    notifyListeners();
  }
}
