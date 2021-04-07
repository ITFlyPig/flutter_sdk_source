import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_app/i_lru_cache.dart';

class LruCache extends ILruCache {
  final int _maxNum;
  late LinkedHashMap<int, RenderObject> _cache;

  LruCache(this._maxNum) {
    _cache = new LinkedHashMap();
  }

  @override
  RenderObject? get(int key) {
    _cache.remove(key);
  }

  @override
  put(int key, RenderObject obj) {
    //缓存
    _cache[key] = obj;
    //判断限制
    while (_cache.length > _maxNum) {
      //删除最近最少使用的
      _cache.remove(_cache.keys.last);
    }
  }

  @override
  RenderObject? remove(int key) {
    return _cache.remove(key);
  }
}
