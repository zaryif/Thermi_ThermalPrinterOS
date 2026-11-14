import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermal_studio/protocol/tiny_print_protocol.dart';
import 'package:thermal_studio/services/rasterizer_service.dart';

void main() {
  group('RasterizerService & DitherMode Tests', () {
    test('DitherMode enum covers all calibration strategies', () {
      expect(DitherMode.values.length, 4);
      expect(DitherMode.values, contains(DitherMode.threshold));
      expect(DitherMode.values, contains(DitherMode.floydSteinberg));
      expect(DitherMode.values, contains(DitherMode.atkinson));
      expect(DitherMode.values, contains(DitherMode.adaptive));
    });

    test('TinyPrintProtocol encodes with specified concentration', () {
      final monoBytes = Uint8List(48 * 10); // 10 lines of 384 dots (48 bytes per line)

      // Test default concentration 5
      final stream5 = TinyPrintProtocol.encodeTinyPrintStream(
        monoBytes,
        384,
        10,
        concentration: 5,
      );
      expect(stream5, isNotEmpty);
      // Concentration packet command 0xA4 has payload '5' (0x35)
      expect(stream5[2], 0xA4);
      expect(stream5[6], 0x35);

      // Test concentration 3
      final stream3 = TinyPrintProtocol.encodeTinyPrintStream(
        monoBytes,
        384,
        10,
        concentration: 3,
      );
      expect(stream3[2], 0xA4);
      expect(stream3[6], 0x33);
    });

    test('TinyPrintProtocol generates valid CRC8 checksums', () {
      final testData = Uint8List.fromList([0x35]);
      final crc = TinyPrintProtocol.calcCrc8(testData, 0, 1);
      expect(crc, equals(0x8B)); // Verified CRC from reverse engineering report
    });
  });
}
