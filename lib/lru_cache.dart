import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_app/i_lru_cache.dart';

class LruCache extends ILruCache {
  final int _maxNum;
  late LinkedHashMap<int?, RenderBox> _cache;

  LruCache(this._maxNum) {
    _cache = new LinkedHashMap();
  }

  @override
  RenderBox? get(int? key) {
    return _cache.remove(key);
  }

  @override
  RenderBox? put(int? key, RenderBox obj) {
    //缓存
    _cache[key] = obj;
    //判断限制
    if (_cache.length > _maxNum) {
      //删除最近最少使用的
      return remove(_cache.keys.last);
    }
    return null;
  }

  @override
  RenderBox? remove(int? key) {
    return _cache.remove(key);
  }

  @override
  int length() {
    return _cache.length;
  }
}
