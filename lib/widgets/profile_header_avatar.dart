import 'package:flutter/material.dart';

import '../config/theme.dart';

/// Profile header: avatar + optional camera badge (no frame overlay).
Widget profileHeaderAvatarStack({
  required double avatarDiameter,
  required Widget avatar,
  required bool showCameraBadge,
  required VoidCallback onCameraTap,
  required bool cameraBusy,
}) {
  return SizedBox(
    width: avatarDiameter,
    height: avatarDiameter,
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (showCameraBadge)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onCameraTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: cameraBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
              ),
            ),
          ),
      ],
    ),
  );
}
