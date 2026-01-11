import 'dart:js_interop';

@JS('Y.Doc')
extension type YDoc._(JSObject _) implements JSObject {
  external factory YDoc([YDocOptions? options]);
  external YText getText(String name);
  external YMap getMap(String name);
  external YArray getArray(String name);
  external void on(String event, JSFunction callback);
  external void destroy();

  /// Get the client ID for this document
  external int get clientID;
}

@JS()
@anonymous
extension type YDocOptions._(JSObject _) implements JSObject {
  external factory YDocOptions({bool? gc, int? guid, JSObject? meta});
}

@JS()
extension type YText._(JSObject _) implements JSObject {
  @JS('toString')
  external String jsToString();
  external void insert(int index, String content, [JSObject? attributes]);
  external void delete(int index, int length);
  external void observe(JSFunction callback);
  external void unobserve(JSFunction callback);
  @JS('toJSON')
  external String toJSONString();
}

@JS()
extension type YMap._(JSObject _) implements JSObject {
  external void set(String key, JSAny? value);
  external JSAny? get(String key);
  external bool has(String key);
  external void delete(String key);
  external void observe(JSFunction callback);
  external void unobserve(JSFunction callback);
  @JS('toJSON')
  external JSAny toJSON();
}

@JS()
extension type YArray._(JSObject _) implements JSObject {
  external void insert(int index, JSArray content);
  external void delete(int index, int length);
  external void push(JSArray content);
  external JSAny get(int index);
  external int get length;
  external void observe(JSFunction callback);
  external void unobserve(JSFunction callback);
  @JS('toJSON')
  external JSAny toJSON();
}

@JS()
extension type YEvent._(JSObject _) implements JSObject {
  external JSAny get target;
  external JSAny get currentTarget;
}
