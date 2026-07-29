// Stub untuk platform non-web (Android, iOS, Desktop)
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<XFile?> openWebCameraInput() async {
  return null;
}

Future<Uint8List?> captureFromWebCamera(BuildContext context) async {
  return null;
}
