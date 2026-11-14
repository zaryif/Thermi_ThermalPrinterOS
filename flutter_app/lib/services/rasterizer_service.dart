import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Dithering algorithm selection for thermal print binarization.
enum DitherMode {
  /// Hard threshold — best for text-only receipts (crisp, zero fuzz).
  threshold,

  /// Floyd-Steinberg error diffusion — best for photos & images.
  floydSteinberg,

  /// Apple Atkinson dithering — ultra-crisp halftone, good for line art.
  atkinson,

  /// Adaptive threshold — per-row local mean, great for mixed content.
  adaptive,
}

class RasterResult {
  final Uint8List monoBytes;
  final int widthDots;
  final int heightDots;

  RasterResult({
    required this.monoBytes,
    required this.widthDots,
    required this.heightDots,
  });
}

class RasterizerService {
  /// Captures a RenderRepaintBoundary directly to 1-bit monochrome bytes.
  ///
  /// Matches the Capacitor / Tiny Print reference pipeline:
  /// - Luminance: 0.299*R + 0.587*G + 0.114*B
  /// - Configurable contrast factor (default 1.15)
  /// - Configurable binarization threshold (default 138)
  /// - LSB-first bit packing (Bit 0 = leftmost dot, Bit 7 = rightmost dot)
  /// - Floyd-Steinberg / Atkinson dithering for photo content
  static Future<RasterResult> captureReceiptToMono(
    GlobalKey boundaryKey,
    int targetWidthDots, {
    DitherMode ditherMode = DitherMode.threshold,
    int threshold = 138,
    double contrast = 1.15,
  }) async {
    final RenderRepaintBoundary? boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      throw Exception('RepaintBoundary not found for receipt key');
    }

    // Determine precise pixel ratio to render directly at native hardware dot width
    final double actualWidth = boundary.size.width;
    final double pixelRatio = actualWidth > 0 ? (targetWidthDots / actualWidth) : 1.0;

    // 1. Capture live Flutter widget to uncompressed RGBA image at target dot density
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw Exception('Failed to obtain raw RGBA byte data from canvas image');
    }

    final int width = image.width;
    final int height = image.height;
    final Uint8List rgba = byteData.buffer.asUint8List();

    // 2. Build grayscale buffer with contrast adjustment (Float64 for dithering precision)
    final Float64List grayBuffer = Float64List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = (y * width + x) * 4;
        final int r = rgba[idx];
        final int g = rgba[idx + 1];
        final int b = rgba[idx + 2];
        final int a = rgba[idx + 3];

        double gray;
        if (a < 255) {
          final double alpha = a / 255.0;
          final double br = r * alpha + 255 * (1 - alpha);
          final double bg = g * alpha + 255 * (1 - alpha);
          final double bb = b * alpha + 255 * (1 - alpha);
          gray = 0.299 * br + 0.587 * bg + 0.114 * bb;
        } else {
          gray = 0.299 * r + 0.587 * g + 0.114 * b;
        }

        // Contrast adjustment matching Capacitor printEngine.ts
        final double adjusted = ((gray - 128.0) * contrast + 128.0).clamp(0.0, 255.0);
        grayBuffer[y * width + x] = adjusted;
      }
    }

    // 3. Binarize using selected dithering algorithm
    final Uint8List mono = Uint8List(width * height); // 0=white, 1=black

    switch (ditherMode) {
      case DitherMode.threshold:
        _applyThreshold(grayBuffer, mono, width, height, threshold);
        break;
      case DitherMode.floydSteinberg:
        _applyFloydSteinberg(grayBuffer, mono, width, height, threshold);
        break;
      case DitherMode.atkinson:
        _applyAtkinson(grayBuffer, mono, width, height, threshold);
        break;
      case DitherMode.adaptive:
        _applyAdaptiveThreshold(grayBuffer, mono, width, height);
        break;
    }

    // 4. LSB-first bit packing into thermal raster bytes
    final int bytesPerRow = (targetWidthDots + 7) ~/ 8;
    final Uint8List packedBytes = Uint8List(bytesPerRow * height);

    for (int y = 0; y < height; y++) {
      final int targetRowOffset = y * bytesPerRow;
      for (int x = 0; x < targetWidthDots && x < width; x++) {
        if (mono[y * width + x] == 1) {
          final int byteIdx = targetRowOffset + (x ~/ 8);
          final int bitPos = x % 8; // LSB first for hardware
          packedBytes[byteIdx] |= (1 << bitPos);
        }
      }
    }

    return RasterResult(
      monoBytes: packedBytes,
      widthDots: targetWidthDots,
      heightDots: height,
    );
  }

  /// Pure threshold binarization — crisp text, no halftone.
  static void _applyThreshold(
    Float64List gray, Uint8List mono, int w, int h, int threshold,
  ) {
    for (int i = 0; i < gray.length; i++) {
      mono[i] = gray[i] < threshold ? 1 : 0;
    }
  }

  /// Floyd-Steinberg error diffusion dithering.
  /// Matches Capacitor imageDithering.ts and Tiny Print ImageDisposeUtil.java.
  ///
  ///     X   7/16
  /// 3/16 5/16 1/16
  static void _applyFloydSteinberg(
    Float64List gray, Uint8List mono, int w, int h, int threshold,
  ) {
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final int idx = y * w + x;
        final double oldVal = gray[idx];
        final double newVal = oldVal < threshold ? 0.0 : 255.0;
        mono[idx] = newVal == 0.0 ? 1 : 0;
        final double err = oldVal - newVal;

        if (x + 1 < w) {
          gray[idx + 1] += err * 7.0 / 16.0;
        }
        if (x - 1 >= 0 && y + 1 < h) {
          gray[(y + 1) * w + (x - 1)] += err * 3.0 / 16.0;
        }
        if (y + 1 < h) {
          gray[(y + 1) * w + x] += err * 5.0 / 16.0;
        }
        if (x + 1 < w && y + 1 < h) {
          gray[(y + 1) * w + (x + 1)] += err * 1.0 / 16.0;
        }
      }
    }
  }

  /// Apple Atkinson dithering — distributes 6/8 of error to 6 neighbors.
  /// Produces ultra-crisp halftone with slightly less shadow detail than F-S.
  static void _applyAtkinson(
    Float64List gray, Uint8List mono, int w, int h, int threshold,
  ) {
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final int idx = y * w + x;
        final double oldVal = gray[idx];
        final double newVal = oldVal < threshold ? 0.0 : 255.0;
        mono[idx] = newVal == 0.0 ? 1 : 0;
        final double err = (oldVal - newVal) / 8.0;

        if (x + 1 < w) gray[idx + 1] += err;
        if (x + 2 < w) gray[idx + 2] += err;
        if (x - 1 >= 0 && y + 1 < h) gray[(y + 1) * w + (x - 1)] += err;
        if (y + 1 < h) gray[(y + 1) * w + x] += err;
        if (x + 1 < w && y + 1 < h) gray[(y + 1) * w + (x + 1)] += err;
        if (y + 2 < h) gray[(y + 2) * w + x] += err;
      }
    }
  }

  /// Adaptive threshold — per-row local mean minus offset (13).
  /// Matches Tiny Print's format_K_threshold for mixed text/graphics.
  static void _applyAdaptiveThreshold(
    Float64List gray, Uint8List mono, int w, int h,
  ) {
    for (int y = 0; y < h; y++) {
      // Calculate row mean luminance
      double rowSum = 0;
      for (int x = 0; x < w; x++) {
        rowSum += gray[y * w + x];
      }
      final double rowMean = rowSum / w;
      final double localThreshold = rowMean - 13; // Tiny Print offset

      for (int x = 0; x < w; x++) {
        final int idx = y * w + x;
        mono[idx] = gray[idx] < localThreshold ? 1 : 0;
      }
    }
  }
}
