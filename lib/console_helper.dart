import 'dart:ffi' as ffi;

void attachParentConsole() {
  const attachParentProcess = 0xFFFFFFFF;
  final kernel32 = ffi.DynamicLibrary.open('kernel32.dll');
  final attachConsole = kernel32.lookupFunction<ffi.Int32 Function(ffi.Uint32),
      int Function(int)>('AttachConsole');
  attachConsole(attachParentProcess);
}
