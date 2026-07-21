import 'dart:io';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.path,
    required this.size,
    super.key,
  });

  final String path;
  final double size;

  bool get _isFilePath => path.startsWith('/');

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: _isFilePath
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
              )
            : Image.asset(
                path,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
