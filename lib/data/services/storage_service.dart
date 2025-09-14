import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'dart:convert';

class StorageService extends GetxService {
  late FlutterSecureStorage _storage;

  Future<void> init() async {
    _storage = const FlutterSecureStorage();
    // A small delay to ensure initialization is complete
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  static const String keyFirstLaunch = 'first_launch';
  static const String keyUserData = 'user_data';
  static const String keyAuthToken = 'auth_token';
  static const String keyDeviceId = 'device_id';
  static const String keyVerificationQueue = 'verification_queue';
  
  
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }
  
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
  
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
  
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
  
  Future<void> saveObject(String key, Map<String, dynamic> object) async {
    final jsonString = json.encode(object);
    await write(key, jsonString);
  }
  
  Future<Map<String, dynamic>?> getObject(String key) async {
    final jsonString = await read(key);
    if (jsonString != null) {
      return json.decode(jsonString);
    }
    return null;
  }
  
  Future<void> saveList(String key, List<dynamic> list) async {
    final jsonString = json.encode(list);
    await write(key, jsonString);
  }
  
  Future<List<dynamic>?> getList(String key) async {
    final jsonString = await read(key);
    if (jsonString != null) {
      return json.decode(jsonString);
    }
    return null;
  }
  
  Future<bool> isFirstLaunch() async {
    final value = await read(keyFirstLaunch);
    return value == null || value == 'true';
  }
  
  Future<void> setFirstLaunch(bool value) async {
    await write(keyFirstLaunch, value.toString());
  }
  
  Future<void> saveAuthToken(String token) async {
    await write(keyAuthToken, token);
  }
  
  Future<String?> getAuthToken() async {
    return await read(keyAuthToken);
  }
  
  Future<void> clearAuthData() async {
    await delete(keyAuthToken);
    await delete(keyUserData);
  }
  
  Future<void> addToVerificationQueue(Map<String, dynamic> data) async {
    List<dynamic> queue = await getList(keyVerificationQueue) ?? [];
    queue.add(data);
    await saveList(keyVerificationQueue, queue);
  }
  
  Future<List<dynamic>> getVerificationQueue() async {
    return await getList(keyVerificationQueue) ?? [];
  }
  
  Future<void> clearVerificationQueue() async {
    await delete(keyVerificationQueue);
  }
}