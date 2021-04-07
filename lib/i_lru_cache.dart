import 'package:flutter/material.dart';

abstract class ILruCache<T extends RenderObject> {
  put(int key, T obj);
  T? get(int key);
  T? remove(int key);
}
