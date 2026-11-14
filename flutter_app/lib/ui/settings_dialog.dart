import 'package:flutter/material.dart';
import '../models/receipt_models.dart';
import '../services/rasterizer_service.dart';

class SettingsDialog extends StatefulWidget {
  final PaperWidth paperWidth;
  final Function(PaperWidth) onPaperWidthChange;
  final ReceiptFontFamily fontFamily;
  final Function(ReceiptFontFamily) onFontFamilyChange;
  final VoidCallback onReplayOnboarding;
  final int concentration;
  final Function(int) onConcentrationChange;
  final DitherMode ditherMode;
  final Function(DitherMode) onDitherModeChange;
  final int threshold;
  final Function(int) onThresholdChange;
  final double contrast;
  final Function(double) onContrastChange;

  const SettingsDialog({
    super.key,
    required this.paperWidth,
    required this.onPaperWidthChange,
    required this.fontFamily,
    required this.onFontFamilyChange,
    required this.onReplayOnboarding,
    this.concentration = 5,
    required this.onConcentrationChange,
    this.ditherMode = DitherMode.threshold,
    required this.onDitherModeChange,
    this.threshold = 138,
    required this.onThresholdChange,
    this.contrast = 1.15,
    required this.onContrastChange,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late int _concentration;
  late DitherMode _ditherMode;
  late int _threshold;
  late double _contrast;

  @override
  void initState() {
    super.initState();
    _concentration = widget.concentration;
    _ditherMode = widget.ditherMode;
    _threshold = widget.threshold;
    _contrast = widget.contrast;
  }

  String _ditherModeLabel(DitherMode mode) {
    switch (mode) {
      case DitherMode.threshold:
        return 'Threshold';
      case DitherMode.floydSteinberg:
        return 'Floyd-Steinberg';
      case DitherMode.atkinson:
        return 'Atkinson';
      case DitherMode.adaptive:
        return 'Adaptive';
    }
  }

  String _ditherModeDescription(DitherMode mode) {
    switch (mode) {
      case DitherMode.threshold:
        return 'Best for text — sharp edges, no halftone';
      case DitherMode.floydSteinberg:
        return 'Best for photos — smooth gradient halftone';
      case DitherMode.atkinson:
        return 'Crisp halftone — ideal for line art and logos';
      case DitherMode.adaptive:
        return 'Mixed content — auto-adjusts per row';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121215),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF27272A)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings & System',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Thermi — Your Thermal Printer OS',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFA1A1AA),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF27272A)),

            // Content List
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                children: [
                  // Section: Hardware & Calibration
                  _buildSectionHeader('HARDWARE & PAPER'),
                  const SizedBox(height: 8),

                  _buildSettingCard(
                    title: 'Paper Roll Width',
                    subtitle: 'Select thermal paper width standard',
                    trailing: SegmentedButton<PaperWidth>(
                      segments: const [
                        ButtonSegment(value: PaperWidth.mm58, label: Text('58mm', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: PaperWidth.mm80, label: Text('80mm', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {widget.paperWidth},
                      onSelectionChanged: (set) {
                        if (set.isNotEmpty) widget.onPaperWidthChange(set.first);
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFFF59E0B);
                          }
                          return const Color(0xFF18181B);
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF09090B);
                          }
                          return Colors.white70;
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section: Print Quality Engine
                  _buildSectionHeader('PRINT QUALITY ENGINE'),
                  const SizedBox(height: 8),

                  // Concentration Level
                  _buildSettingCard(
                    title: 'Print Density (Concentration)',
                    subtitle: 'Level $_concentration — ${_concentration >= 4 ? "Deep black" : _concentration >= 3 ? "Standard" : "Light"}',
                    trailing: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Slider(
                              value: _concentration.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              activeColor: const Color(0xFFF59E0B),
                              inactiveColor: const Color(0xFF27272A),
                              onChanged: (val) {
                                setState(() => _concentration = val.round());
                                widget.onConcentrationChange(_concentration);
                              },
                            ),
                          ),
                          Text(
                            '$_concentration',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Dithering Algorithm
                  _buildSettingCard(
                    title: 'Dithering Algorithm',
                    subtitle: _ditherModeDescription(_ditherMode),
                    trailing: DropdownButton<DitherMode>(
                      value: _ditherMode,
                      dropdownColor: const Color(0xFF18181B),
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _ditherMode = val);
                          widget.onDitherModeChange(val);
                        }
                      },
                      items: DitherMode.values.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(_ditherModeLabel(mode)),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Threshold
                  _buildSettingCard(
                    title: 'Binarization Threshold',
                    subtitle: '$_threshold / 255 — ${_threshold > 140 ? "Darker output" : _threshold < 120 ? "Lighter output" : "Balanced"}',
                    trailing: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Slider(
                              value: _threshold.toDouble(),
                              min: 80,
                              max: 200,
                              divisions: 24,
                              activeColor: const Color(0xFFF59E0B),
                              inactiveColor: const Color(0xFF27272A),
                              onChanged: (val) {
                                setState(() => _threshold = val.round());
                                widget.onThresholdChange(_threshold);
                              },
                            ),
                          ),
                          Text(
                            '$_threshold',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Contrast
                  _buildSettingCard(
                    title: 'Contrast Enhancement',
                    subtitle: '${_contrast.toStringAsFixed(2)}x — ${_contrast > 1.2 ? "High contrast" : _contrast < 1.0 ? "Soft" : "Calibrated"}',
                    trailing: SizedBox(
                      width: 120,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Slider(
                              value: _contrast,
                              min: 0.5,
                              max: 2.0,
                              divisions: 15,
                              activeColor: const Color(0xFFF59E0B),
                              inactiveColor: const Color(0xFF27272A),
                              onChanged: (val) {
                                setState(() => _contrast = double.parse(val.toStringAsFixed(2)));
                                widget.onContrastChange(_contrast);
                              },
                            ),
                          ),
                          Text(
                            _contrast.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildSettingCard(
                    title: 'BLE Packet Streaming',
                    subtitle: '177 bytes / 50ms pacing (FIFO protected)',
                    trailing: const Text(
                      'Paced',
                      style: TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section: Typography & App
                  _buildSectionHeader('TYPOGRAPHY & DISPLAY'),
                  const SizedBox(height: 8),

                  _buildSettingCard(
                    title: 'Default Font Family',
                    subtitle: 'Thermal head rendering style',
                    trailing: DropdownButton<ReceiptFontFamily>(
                      value: widget.fontFamily,
                      dropdownColor: const Color(0xFF18181B),
                      underline: const SizedBox(),
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      onChanged: (val) {
                        if (val != null) widget.onFontFamilyChange(val);
                      },
                      items: const [
                        DropdownMenuItem(value: ReceiptFontFamily.mono, child: Text('Mono POS')),
                        DropdownMenuItem(value: ReceiptFontFamily.sans, child: Text('Clean Sans')),
                        DropdownMenuItem(value: ReceiptFontFamily.serif, child: Text('Editorial Serif')),
                        DropdownMenuItem(value: ReceiptFontFamily.typewriter, child: Text('Typewriter')),
                        DropdownMenuItem(value: ReceiptFontFamily.terminal, child: Text('Retro Arcade')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildSettingCard(
                    title: 'Welcome Walkthrough',
                    subtitle: 'Replay the first-time setup guide',
                    trailing: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onReplayOnboarding();
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFFF59E0B),
                      ),
                      child: const Text('Replay', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Section: About Developer & System
                  _buildSectionHeader('ABOUT DEVELOPER & SYSTEM'),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF27272A)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thermi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'v1.4.0',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your Thermal Printer Solution',
                          style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                        ),
                        SizedBox(height: 12),
                        Divider(height: 1, color: Color(0xFF27272A)),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Lead Developer: ',
                              style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                            ),
                            Text(
                              'MD. ZARIF AZFAR',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Architecture: ',
                              style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                            ),
                            Text(
                              'Pure Flutter & Universal Thermal Engine',
                              style: TextStyle(fontSize: 11, color: Colors.white70),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Supported Hardware: ',
                              style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                            ),
                            Expanded(
                              child: Text(
                                'Pocket, Cat, POS, and Standard 58mm/80mm Printers',
                                style: TextStyle(fontSize: 11, color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Color(0xFF71717A),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
