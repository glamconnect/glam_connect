import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  static Future<String?> processAndEncodeImage(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return null;

      // Calculate new dimensions maintaining aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;
      
      if (newWidth > newHeight) {
        if (newWidth > 150) {
          newHeight = (150 * newHeight ~/ newWidth);
          newWidth = 150;
        }
      } else {
        if (newHeight > 150) {
          newWidth = (150 * newWidth ~/ newHeight);
          newHeight = 150;
        }
      }

      // Resize the image
      final resizedImage = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode to PNG format
      final compressedBytes = img.encodePng(resizedImage);

      // Convert to base64
      final base64String = base64Encode(compressedBytes);
      
      return base64String;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }

  static ImageProvider getImageProvider(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const AssetImage('assets/images/placeholder.png');
    }

    try {
      final bytes = base64Decode(base64String);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('Error decoding image: $e');
      return const AssetImage('assets/images/placeholder.png');
    }
  }
}
