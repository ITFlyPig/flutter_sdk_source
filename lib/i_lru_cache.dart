import 'package:flutter/material.dart';

abstract class ILruCache<T extends RenderBox> {
  T? put(int? key, T obj);
  T? get(int? key);
  T? remove(int? key);
  Iterable<T> getAllValue();
  clearAll();
  bool containsValue(T value);
}
