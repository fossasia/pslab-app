import 'package:flutter/services.dart';
import 'dart:io';
import 'package:pslab/others/logger_service.dart';

enum AppPermission { microphone, location }

enum AppPermissionStatus { granted, denied, permanentlyDenied }

class PSLabPermissions {
  static const MethodChannel _channel = MethodChannel('io.pslab/permissions');

  static Future<AppPermissionStatus> checkStatus(
      AppPermission permission) async {
    if (Platform.isWindows || Platform.isLinux) {
      return AppPermissionStatus.granted;
    }

    try {
      final String? result = await _channel.invokeMethod('checkStatus', {
        'permission': permission.name,
      });
      return _parseStatus(result);
    } on PlatformException catch (e) {
      _logError('checkStatus', e);
      return AppPermissionStatus.denied;
    }
  }

  static Future<AppPermissionStatus> request(AppPermission permission) async {
    if (Platform.isWindows || Platform.isLinux) {
      return AppPermissionStatus.granted;
    }

    try {
      final String? result = await _channel.invokeMethod('request', {
        'permission': permission.name,
      });
      return _parseStatus(result);
    } on PlatformException catch (e) {
      _logError('request', e);
      return AppPermissionStatus.denied;
    }
  }

  static AppPermissionStatus _parseStatus(String? status) {
    switch (status) {
      case 'granted':
        return AppPermissionStatus.granted;
      case 'permanentlyDenied':
        return AppPermissionStatus.permanentlyDenied;
      case 'denied':
      default:
        return AppPermissionStatus.denied;
    }
  }

  static void _logError(String method, PlatformException exception) {
    logger.e(
        'PSLabPermissions Error during $method: ${exception.message} (Code: ${exception.code})');
  }
}
