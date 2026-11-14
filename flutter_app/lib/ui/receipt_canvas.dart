import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/receipt_models.dart';

class ReceiptCanvas extends StatelessWidget {
  final GlobalKey receiptKey;
  final List<ReceiptBlock> blocks;
  final PaperWidth paperWidth;
  final ReceiptFontFamily fontFamily;
  final String? selectedBlockId;
  final Function(String) onSelectBlock;
  final Function(ReceiptBlock) onUpdateBlock;
  final Function(String, String) onMoveBlock;
  final Function(String) onDeleteBlock;
  final Function(ImageBlock) onPickImage;
  final VoidCallback onAddEventToSchedule;
  final VoidCallback onAddTaskToTodo;
  final bool isPreviewMode;
  final bool isPrinting;

  const ReceiptCanvas({
    super.key,
    required this.receiptKey,
    required this.blocks,
    required this.paperWidth,
    required this.fontFamily,
    required this.selectedBlockId,
    required this.onSelectBlock,
    required this.onUpdateBlock,
    required this.onMoveBlock,
    required this.onDeleteBlock,
    required this.onPickImage,
    required this.onAddEventToSchedule,
    required this.onAddTaskToTodo,
    this.isPreviewMode = false,
    this.isPrinting = false,
  });

  static const List<Map<String, String>> curatedQuotes = [
    {
      'quote': 'Think & Change.',
      'author': 'MD. ZARIF AZFAR',
      'category': 'Vision',
    },
    {
      'quote': 'The obstacle in the path becomes the path. Never forget, within every obstacle is an opportunity.',
      'author': 'Marcus Aurelius',
      'category': 'Stoicism',
    },
    {
      'quote': 'Stay hungry, stay foolish. Make a dent in the universe.',
      'author': 'Steve Jobs',
      'category': 'Innovation',
    },
    {
      'quote': 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
      'author': 'Will Durant',
      'category': 'Focus',
    },
    {
      'quote': 'It is not that we have a short time to live, but that we waste a lot of it.',
      'author': 'Seneca',
      'category': 'Discipline',
    },
    {
      'quote': 'Focus is a matter of deciding what things you are NOT going to do.',
      'author': 'John Carmack',
      'category': 'Architecture',
    },
    {
      'quote': 'Simplicity is prerequisite for reliability.',
      'author': 'Edsger W. Dijkstra',
      'category': 'Engineering',
    },
    {
      'quote': 'Small daily improvements over time lead to stunning results.',
      'author': 'Robin Sharma',
      'category': 'Growth',
    },
    {
      'quote': 'Do what you can, with what you have, where you are.',
      'author': 'Theodore Roosevelt',
      'category': 'Action',
    },
    {
      'quote': 'Action is the foundational key to all success.',
      'author': 'Pablo Picasso',
      'category': 'Creation',
    },
  ];

  bool get isCleanMode => isPreviewMode || isPrinting;

  TextStyle getBaseTextStyle({
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.w600,
    FontStyle fontStyle = FontStyle.normal,
    Color color = const Color(0xFF09090B),
    double height = 1.35,
  }) {
    switch (fontFamily) {
      case ReceiptFontFamily.mono:
        return GoogleFonts.spaceMono(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          height: height,
        );
      case ReceiptFontFamily.sans:
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          height: height,
        );
      case ReceiptFontFamily.serif:
        return GoogleFonts.playfairDisplay(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          height: height,
        );
      case ReceiptFontFamily.terminal:
        return GoogleFonts.vt323(
          fontSize: fontSize + 2.0,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          height: height,
        );
      case ReceiptFontFamily.typewriter:
        return GoogleFonts.courierPrime(
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          height: height,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Fits screen width seamlessly without horizontal scrolling
        final double maxAvailable = constraints.maxWidth - 20;
        final double targetWidth = paperWidth == PaperWidth.mm58 ? 360.0 : 420.0;
        final double displayWidth = targetWidth > maxAvailable && maxAvailable > 200 ? maxAvailable : targetWidth;

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Top paper roll visual feed dispenser
                Container(
                  width: displayWidth,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF18181B),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF09090B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // Live RepaintBoundary: Captured directly to monochrome bitmap for printing
                RepaintBoundary(
                  key: receiptKey,
                  child: Container(
                    width: displayWidth,
                    padding: EdgeInsets.symmetric(
                      horizontal: isCleanMode ? 14 : 16,
                      vertical: isCleanMode ? 16 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAF9), // Off-white thermal stock
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    if (blocks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'EMPTY RECEIPT',
                              style: getBaseTextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap any template block above to start typing directly',
                              style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      )
                    else
                      ...blocks.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final ReceiptBlock block = entry.value;
                        final bool isSelected = !isCleanMode && block.id == selectedBlockId;

                        return GestureDetector(
                          onTap: isCleanMode ? null : () => onSelectBlock(block.id),
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: isCleanMode ? 2 : 4),
                            padding: EdgeInsets.all(isCleanMode ? 0 : 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _buildBlockContent(block),

                                // Block action overlay when selected
                                if (isSelected && !isCleanMode)
                                  Positioned(
                                    top: -12,
                                    right: 0,
                                    child: Material(
                                      color: const Color(0xFF18181B),
                                      borderRadius: BorderRadius.circular(6),
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (block is QuoteBlock)
                                              InkWell(
                                                onTap: () {
                                                  final next = (ReceiptCanvas.curatedQuotes.toList()..shuffle()).first;
                                                  block.quote = next['quote']!;
                                                  block.author = next['author']!;
                                                  block.category = next['category']!;
                                                  onUpdateBlock(block);
                                                },
                                                child: const Tooltip(
                                                  message: 'Shuffle Quote',
                                                  child: Padding(
                                                    padding: EdgeInsets.all(2),
                                                    child: Icon(Icons.shuffle_rounded, size: 14, color: Colors.amber),
                                                  ),
                                                ),
                                              ),
                                            if (index > 0)
                                              InkWell(
                                                onTap: () => onMoveBlock(block.id, 'up'),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(2),
                                                  child: Icon(Icons.arrow_upward, size: 14, color: Colors.amber),
                                                ),
                                              ),
                                            if (index < blocks.length - 1)
                                              InkWell(
                                                onTap: () => onMoveBlock(block.id, 'down'),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(2),
                                                  child: Icon(Icons.arrow_downward, size: 14, color: Colors.amber),
                                                ),
                                              ),
                                            InkWell(
                                              onTap: () => onDeleteBlock(block.id),
                                              child: const Padding(
                                                padding: EdgeInsets.all(2),
                                                child: Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // Bottom paper roll finished edge
            Container(
              width: displayWidth,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFE4E4E7),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildBlockContent(ReceiptBlock block) {
    if (block is HeaderBlock) {
      return Column(
        children: [
          TextFormField(
            initialValue: block.title,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textAlign: TextAlign.center,
            style: getBaseTextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.25),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 2),
            ),
            onChanged: (val) {
              block.title = val;
              onUpdateBlock(block);
            },
          ),
          TextFormField(
            initialValue: block.subtitle,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textAlign: TextAlign.center,
            style: getBaseTextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.grey.shade800, height: 1.25),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 2),
            ),
            onChanged: (val) {
              block.subtitle = val;
              onUpdateBlock(block);
            },
          ),
          TextFormField(
            initialValue: block.dateStr,
            textAlign: TextAlign.center,
            style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 2),
            ),
            onChanged: (val) {
              block.dateStr = val;
              onUpdateBlock(block);
            },
          ),
          const Divider(thickness: 1, color: Colors.black26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: block.metaLeft,
                  style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 2),
                  ),
                  onChanged: (val) {
                    block.metaLeft = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: block.metaRight,
                  textAlign: TextAlign.right,
                  style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 2),
                  ),
                  onChanged: (val) {
                    block.metaRight = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (block is TextBlock) {
      return Container(
        color: block.inverted ? Colors.black : Colors.transparent,
        padding: block.inverted ? const EdgeInsets.all(6) : const EdgeInsets.symmetric(vertical: 2),
        child: TextFormField(
          initialValue: block.text,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textAlign: block.align,
          style: getBaseTextStyle(
            fontSize: block.fontSize,
            fontWeight: block.bold ? FontWeight.w900 : FontWeight.w700,
            color: block.inverted ? Colors.white : const Color(0xFF09090B),
            height: 1.35,
          ),
          decoration: const InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          ),
          onChanged: (val) {
            block.text = val;
            onUpdateBlock(block);
          },
        ),
      );
    }

    if (block is ImageBlock) {
      if (block.imageBytes == null) {
        if (isCleanMode) {
          return const SizedBox.shrink();
        }
        return InkWell(
          onTap: () => onPickImage(block),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.grey.shade600),
                const SizedBox(height: 4),
                Text(
                  'Tap to Upload Photo',
                  style: getBaseTextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                Text(
                  'Automatic thermal contrast & Floyd-Steinberg dither',
                  style: getBaseTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Image.memory(
              block.imageBytes!,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          if (!isCleanMode) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => onPickImage(block),
                  icon: const Icon(Icons.refresh, size: 12, color: Colors.black87),
                  label: Text('Change Photo', style: getBaseTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 20)),
                ),
                TextButton(
                  onPressed: () {
                    block.imageBytes = null;
                    onUpdateBlock(block);
                  },
                  child: Text('Clear Photo', style: getBaseTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                ),
              ],
            ),
          ],
          if (block.caption.isNotEmpty || !isCleanMode)
            TextFormField(
              initialValue: block.caption,
              textAlign: TextAlign.center,
              style: getBaseTextStyle(fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
              decoration: const InputDecoration(
                hintText: 'Add photo caption (optional)',
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
              ),
              onChanged: (val) {
                block.caption = val;
                onUpdateBlock(block);
              },
            ),
        ],
      );
    }

    if (block is QuoteBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F7F6),
          border: Border(left: BorderSide(color: Colors.black87, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: ValueKey('${block.id}_q_${block.quote}'),
              initialValue: block.quote,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: getBaseTextStyle(fontSize: 15.5, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, height: 1.35),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
              ),
              onChanged: (val) {
                block.quote = val;
                onUpdateBlock(block);
              },
            ),
            const SizedBox(height: 2),
            TextFormField(
              key: ValueKey('${block.id}_a_${block.author}'),
              initialValue: '— ${block.author}',
              textAlign: TextAlign.right,
              style: getBaseTextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.grey.shade800),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                block.author = val.replaceAll('—', '').trim();
                onUpdateBlock(block);
              },
            ),
          ],
        ),
      );
    }

    if (block is GapBlock) {
      final isSelected = !isCleanMode && block.id == selectedBlockId;
      return Column(
        children: [
          SizedBox(height: block.height),
          if (isSelected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Gap: ${block.height.toInt()}px', style: getBaseTextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      if (block.height > 4) {
                        block.height -= 4;
                        onUpdateBlock(block);
                      }
                    },
                    child: const Icon(Icons.remove_circle_outline, size: 14, color: Colors.black54),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      if (block.height < 64) {
                        block.height += 4;
                        onUpdateBlock(block);
                      }
                    },
                    child: const Icon(Icons.add_circle_outline, size: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    if (block is ExpenseBlock) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: block.title,
                  style: getBaseTextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  onChanged: (val) {
                    block.title = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
              SizedBox(
                width: 85,
                child: TextFormField(
                  initialValue: block.date,
                  textAlign: TextAlign.right,
                  style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  onChanged: (val) {
                    block.date = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black87),
          ...block.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      initialValue: item.name,
                      style: getBaseTextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        item.name = val;
                        onUpdateBlock(block);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 55,
                    child: TextFormField(
                      initialValue: item.category,
                      textAlign: TextAlign.center,
                      style: getBaseTextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        item.category = val;
                        onUpdateBlock(block);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 55,
                    child: TextFormField(
                      initialValue: '${block.currency}${item.amount.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: getBaseTextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        final clean = val.replaceAll(block.currency, '').trim();
                        final parsed = double.tryParse(clean);
                        if (parsed != null) {
                          item.amount = parsed;
                          onUpdateBlock(block);
                        }
                      },
                    ),
                  ),
                  if (!isCleanMode)
                    InkWell(
                      onTap: () {
                        block.items.removeWhere((i) => i.id == item.id);
                        onUpdateBlock(block);
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.close, size: 12, color: Colors.black38),
                      ),
                    ),
                ],
              ),
            );
          }),
          if (!isCleanMode)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  block.items.add(
                    ExpenseItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: 'Expense Item',
                      category: 'General',
                      amount: 5.00,
                    ),
                  );
                  onUpdateBlock(block);
                },
                icon: const Icon(Icons.add, size: 13, color: Colors.black54),
                label: Text('+ Add Item', style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 22)),
              ),
            ),
          const Divider(thickness: 1.5, color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SUBTOTAL', style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              Text('${block.currency}${block.subtotal.toStringAsFixed(2)}',
                  style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL EXPENSES', style: getBaseTextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
              Text('${block.currency}${block.total.toStringAsFixed(2)}',
                  style: getBaseTextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      );
    }

    if (block is ImportantBlock) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: block.tag,
                    style: getBaseTextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B),
                    ),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    onChanged: (val) {
                      block.tag = val;
                      onUpdateBlock(block);
                    },
                  ),
                ),
                const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 2),
            TextFormField(
              initialValue: block.title,
              maxLines: null,
              style: getBaseTextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.25,
              ),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (val) {
                block.title = val;
                onUpdateBlock(block);
              },
            ),
            const Divider(color: Colors.white24, thickness: 1, height: 8),
            TextFormField(
              initialValue: block.content,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: getBaseTextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.35,
              ),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (val) {
                block.content = val;
                onUpdateBlock(block);
              },
            ),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: block.footer,
              style: getBaseTextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (val) {
                block.footer = val;
                onUpdateBlock(block);
              },
            ),
          ],
        ),
      );
    }

    if (block is ScheduleBlock) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: block.title,
                  maxLines: null,
                  style: getBaseTextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 2),
                  ),
                  onChanged: (val) {
                    block.title = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
              SizedBox(
                width: 85,
                child: TextFormField(
                  initialValue: block.date,
                  textAlign: TextAlign.right,
                  style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 2),
                  ),
                  onChanged: (val) {
                    block.date = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
            ],
          ),
          const Divider(thickness: 1.5, color: Colors.black87),
          ...block.items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      onTap: () {
                        item.done = !item.done;
                        onUpdateBlock(block);
                      },
                      child: Icon(
                        item.done ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.title,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: getBaseTextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: item.done ? Colors.grey.shade400 : Colors.black87,
                        height: 1.3,
                      ).copyWith(
                        decoration: item.done ? TextDecoration.lineThrough : null,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (val) {
                        item.title = val;
                        onUpdateBlock(block);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      initialValue: item.time,
                      textAlign: TextAlign.right,
                      style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade700),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (val) {
                        item.time = val;
                        onUpdateBlock(block);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
          if (!isCleanMode)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  block.items.add(
                    ScheduleItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      time: '12:00 PM',
                      title: 'New Agenda Event',
                    ),
                  );
                  onUpdateBlock(block);
                },
                icon: const Icon(Icons.add, size: 13, color: Colors.black54),
                label: Text('+ Add Event', style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 22)),
              ),
            ),
        ],
      );
    }

    if (block is TodoListBlock) {
      final int completed = block.items.where((i) => i.done).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: block.title,
                  maxLines: null,
                  style: getBaseTextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 2),
                  ),
                  onChanged: (val) {
                    block.title = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
              Text(
                '$completed/${block.items.length}',
                style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black87),
          ...block.items.map((task) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      onTap: () {
                        task.done = !task.done;
                        onUpdateBlock(block);
                      },
                      child: Icon(
                        task.done ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextFormField(
                      initialValue: task.text,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: getBaseTextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: task.done ? Colors.grey.shade400 : Colors.black87,
                        height: 1.3,
                      ).copyWith(
                        decoration: task.done ? TextDecoration.lineThrough : null,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 2),
                      ),
                      onChanged: (val) {
                        task.text = val;
                        onUpdateBlock(block);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      task.isHighPriority = !task.isHighPriority;
                      onUpdateBlock(block);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: task.isHighPriority ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Text(
                        task.isHighPriority ? 'HIGH' : 'LOW',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (!isCleanMode)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  block.items.add(
                    TodoItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      text: 'New checklist task',
                    ),
                  );
                  onUpdateBlock(block);
                },
                icon: const Icon(Icons.add, size: 13, color: Colors.black54),
                label: Text('+ Add Task', style: getBaseTextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 22)),
              ),
            ),
        ],
      );
    }

    if (block is TableBlock) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: block.headers[0],
                  style: getBaseTextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  onChanged: (val) {
                    block.headers[0] = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: block.headers[1],
                  textAlign: TextAlign.center,
                  style: getBaseTextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  onChanged: (val) {
                    block.headers[1] = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: block.headers[2],
                  textAlign: TextAlign.right,
                  style: getBaseTextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  onChanged: (val) {
                    block.headers[2] = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black87),
          ...block.rows.map((row) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: row[0],
                    style: getBaseTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    onChanged: (val) {
                      row[0] = val;
                      onUpdateBlock(block);
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    initialValue: row[1],
                    textAlign: TextAlign.center,
                    style: getBaseTextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    onChanged: (val) {
                      row[1] = val;
                      onUpdateBlock(block);
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: row[2],
                    textAlign: TextAlign.right,
                    style: getBaseTextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                    onChanged: (val) {
                      row[2] = val;
                      onUpdateBlock(block);
                    },
                  ),
                ),
              ],
            );
          }),
          const Divider(thickness: 1.5, color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: block.totalLabel,
                  style: getBaseTextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  onChanged: (val) {
                    block.totalLabel = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
              SizedBox(
                width: 85,
                child: TextFormField(
                  initialValue: block.totalValue,
                  textAlign: TextAlign.right,
                  style: getBaseTextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  onChanged: (val) {
                    block.totalValue = val;
                    onUpdateBlock(block);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (block is QrCodeBlock) {
      return Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              color: Colors.white,
              child: QrImageView(
                data: block.data,
                version: QrVersions.auto,
                size: block.size,
              ),
            ),
            const SizedBox(height: 2),
            TextFormField(
              initialValue: block.data,
              textAlign: TextAlign.center,
              style: getBaseTextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (val) {
                block.data = val;
                onUpdateBlock(block);
              },
            ),
            TextFormField(
              initialValue: block.label,
              textAlign: TextAlign.center,
              style: getBaseTextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onChanged: (val) {
                block.label = val;
                onUpdateBlock(block);
              },
            ),
          ],
        ),
      );
    }

    if (block is DividerBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          block.style == 'stars'
              ? '* * * * * * * * * * * * * * * * * * *'
              : '- - - - - - - - - - - - - - - - - - -',
          textAlign: TextAlign.center,
          style: getBaseTextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (block is FeedBlock) {
      final double feedHeight = (block.lines * 14.0).clamp(16.0, 140.0);
      if (isCleanMode) {
        return SizedBox(height: feedHeight);
      }
      return SizedBox(
        height: feedHeight,
        child: Center(
          child: Text(
            '-- FEED / TEAR SPACE (${block.lines} lines) --',
            style: getBaseTextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
          ),
        ),
      );
    }

    return const SizedBox();
  }
}
