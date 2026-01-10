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
  void insert(int position, String text) {
    if (text.isEmpty) return;
    _text = _text.substring(0, position) + text + _text.substring(position);
    notifyListeners();
  }

  @override
  void delete(int position, int count) {
    if (count <= 0) return;
    _text = _text.substring(0, position) + _text.substring(position + count);
    notifyListeners();
  }
}
