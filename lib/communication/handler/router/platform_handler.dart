export 'platform_handler_stub.dart'
    if (dart.library.io) 'platform_handler_native.dart'
    if (dart.library.js_interop) 'platform_handler_web.dart';
