// Conditional export: use the platform-specific implementation.
export 'socket_client_io.dart' if (dart.library.html) 'socket_client_web.dart';
