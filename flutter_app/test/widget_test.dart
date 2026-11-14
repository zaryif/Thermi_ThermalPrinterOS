import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_studio/main.dart';
import 'package:thermal_studio/models/receipt_models.dart';
import 'package:thermal_studio/ui/receipt_canvas.dart';

void main() {
  testWidgets('ThermalStudioApp basic smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v1': true});
    await tester.pumpWidget(const ThermalStudioApp());
    expect(find.byType(ThermalStudioApp), findsOneWidget);
  });

  testWidgets('ReceiptCanvas in isPrinting mode hides all edit and add controls', (WidgetTester tester) async {
    final receiptKey = GlobalKey();
    final blocks = <ReceiptBlock>[
      TodoListBlock(
        id: 'td_test',
        title: 'TEST TODO',
        items: [TodoItem(id: 't1', text: 'Task 1')],
      ),
      ExpenseBlock(
        id: 'exp_test',
        title: 'TEST EXPENSE',
        currency: '\$',
        date: '2026-11-15',
        items: [ExpenseItem(id: 'e1', name: 'Item 1', category: 'General', amount: 5.0)],
      ),
      ScheduleBlock(
        id: 'sch_test',
        title: 'TEST SCHEDULE',
        date: '2026-11-15',
        items: [ScheduleItem(id: 's1', time: '10:00 AM', title: 'Meeting')],
      ),
      FeedBlock(id: 'fd_test', lines: 3),
    ];

    // 1. Interactive mode (isPrinting: false)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptCanvas(
            receiptKey: receiptKey,
            blocks: blocks,
            paperWidth: PaperWidth.mm58,
            fontFamily: ReceiptFontFamily.mono,
            selectedBlockId: 'td_test',
            onSelectBlock: (_) {},
            onUpdateBlock: (_) {},
            onMoveBlock: (a, b) {},
            onDeleteBlock: (_) {},
            onPickImage: (_) {},
            onAddEventToSchedule: () {},
            onAddTaskToTodo: () {},
            isPreviewMode: false,
            isPrinting: false,
          ),
        ),
      ),
    );

    // Edit controls must be visible in interactive editor
    expect(find.text('+ Add Task'), findsOneWidget);
    expect(find.text('+ Add Item'), findsOneWidget);
    expect(find.text('+ Add Event'), findsOneWidget);
    expect(find.textContaining('FEED / TEAR SPACE'), findsOneWidget);

    // 2. Clean Printing mode (isPrinting: true)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptCanvas(
            receiptKey: receiptKey,
            blocks: blocks,
            paperWidth: PaperWidth.mm58,
            fontFamily: ReceiptFontFamily.mono,
            selectedBlockId: 'td_test',
            onSelectBlock: (_) {},
            onUpdateBlock: (_) {},
            onMoveBlock: (a, b) {},
            onDeleteBlock: (_) {},
            onPickImage: (_) {},
            onAddEventToSchedule: () {},
            onAddTaskToTodo: () {},
            isPreviewMode: false,
            isPrinting: true,
          ),
        ),
      ),
    );

    // Zero UI editing controls must be present when rasterizing for print
    expect(find.text('+ Add Task'), findsNothing);
    expect(find.text('+ Add Item'), findsNothing);
    expect(find.text('+ Add Event'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.textContaining('FEED / TEAR SPACE'), findsNothing);
    expect(find.textContaining('✂'), findsNothing);
  });

  testWidgets('Default template contains no feed tear blocks and no scissor cuts', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding_v1': true});
    await tester.pumpWidget(const ThermalStudioApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('✂'), findsNothing);
    expect(find.textContaining('FEED / TEAR SPACE'), findsNothing);
  });
}
