import 'package:photo_manager/photo_manager.dart';

const _readWrite = PermissionRequestOption(
  iosAccessLevel: IosAccessLevel.readWrite,
);

const _addOnly = PermissionRequestOption(
  iosAccessLevel: IosAccessLevel.addOnly,
);

/// Current library access without prompting "Select More Photos".
Future<PermissionState> peekPhotoLibraryAccess() {
  return PhotoManager.getPermissionState(requestOption: _readWrite);
}

/// Read/write access. Only the first (undetermined) call shows a system prompt.
Future<bool> ensurePhotoLibraryReadAccess() async {
  var state = await peekPhotoLibraryAccess();
  if (state.hasAccess) return true;
  if (state != PermissionState.notDetermined) return false;
  state = await PhotoManager.requestPermissionExtend(requestOption: _readWrite);
  return state.hasAccess;
}

/// Save-to-camera-roll access. Does not open the limited-library picker.
Future<bool> ensurePhotoLibraryAddAccess() async {
  var state = await PhotoManager.getPermissionState(requestOption: _addOnly);
  if (state.hasAccess) return true;
  state = await PhotoManager.requestPermissionExtend(requestOption: _addOnly);
  return state.hasAccess;
}
