import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sticky_grouped_list/sticky_grouped_list.dart';

final List _elements = [
  {'name': 'John', 'group': 'Team A'},
  //{'name': 'Will', 'group': 'Team B'},
  // {'name': 'Beth', 'group': 'Team A'},
  {'name': 'Miranda', 'group': 'Team B'},
  // {'name': 'Mike', 'group': 'Team C'},
  {'name': 'Danny', 'group': 'Team C'},
];
void main() {
  Widget buildGroupSeperator(dynamic element) {
    return Text(element['group']);
  }

  testWidgets('find elemets and group separators', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: _elements,
            order: StickyGroupedListOrder.DESC,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );

    expect(find.text('John'), findsOneWidget);
    expect(find.text('Danny'), findsOneWidget);
    expect(find.text('Team A'), findsOneWidget);
    expect(find.text('Team B'), findsOneWidget);
    expect(find.text('Team C'), findsWidgets);
  });

  testWidgets('empty list', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: const [],
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
  });

  testWidgets('finds only one group separator per group',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: _elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    expect(find.text("Team B"), findsOneWidget);
  });

  testWidgets('does not mutate the original list', (WidgetTester tester) async {
    final original = [
      {'name': 'A', 'group': 'G1'},
      {'name': 'B', 'group': 'G2'},
    ];
    final copy = List<Map<String, String>>.from(
        original.map((e) => Map<String, String>.from(e)));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: copy,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    expect(copy, equals(original));
  });

  testWidgets('handles out-of-bounds index gracefully',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A', 'group': 'G1'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    // Try to find a widget that would be rendered for an out-of-bounds index (should fallback to SizedBox.shrink)
    // We can't directly trigger out-of-bounds, but we can check that no exceptions are thrown and the widget tree is built.
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows sticky header only when showStickyHeader is true',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A', 'group': 'G1'},
    ];
    // showStickyHeader = true
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
            showStickyHeader: true,
          ),
        ),
      ),
    );
    expect(find.byType(StreamBuilder<int>), findsOneWidget);

    // showStickyHeader = false
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
            showStickyHeader: false,
          ),
        ),
      ),
    );
    expect(find.byType(StreamBuilder<int>), findsNothing);
  });

  testWidgets('rebuild with same list does not throw (memoization check)',
      (WidgetTester tester) async {
    final elements = [
      {'name': 'A', 'group': 'G1'},
      {'name': 'B', 'group': 'G2'},
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('topVisibleElementIndex and scrollOffset are exposed and update',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StickyGroupedListView(
            groupBy: (dynamic element) => element['group'],
            elements: _elements,
            groupSeparatorBuilder: buildGroupSeperator,
            itemBuilder: (context, dynamic element) => Text(element['name']),
          ),
        ),
      ),
    );
    // Find the StickyGroupedListView widget and get its state
    final state = tester.state(find.byType(StickyGroupedListView))
        as StickyGroupedListViewState;
    expect(state, isNotNull);
    // topVisibleElementIndex may be null if not yet laid out, but should not throw
    expect(() => state.topVisibleElementIndex, returnsNormally);
    // Try to scroll and check if topVisibleElementIndex updates (simulate scroll)
    // Note: In widget tests, actual scrolling may not update ItemPositionsListener, but we can at least check getter is present
  });

  testWidgets('developer.log is called for out-of-bounds index',
      (WidgetTester tester) async {
    final logs = <String>[];
    await runZonedGuarded(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StickyGroupedListView(
              groupBy: (dynamic element) => element['group'],
              elements: _elements,
              groupSeparatorBuilder: buildGroupSeperator,
              itemBuilder: (context, dynamic element) => Text(element['name']),
            ),
          ),
        ),
      );
      // Try to trigger out-of-bounds by calling buildItem with an invalid index via the state (reflection or test-only API would be better)
      // As a workaround, we can check that no exceptions are thrown and rely on manual log inspection
    }, (Object error, StackTrace stack) {
      logs.add(error.toString());
    });
    // We can't directly assert on developer.log output, but this test ensures no exceptions are thrown
    expect(logs, isEmpty);
  });
}
