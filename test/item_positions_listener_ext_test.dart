import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sticky_grouped_list/src/item_positions_listener_ext.dart';

void main() {
  group('ItemPositionsListenerExt - basic functionality', () {
    test('topItemIndex returns null for empty', () {
      final listener = MockItemPositionsListener([]);
      expect(listener.topItemIndex(), isNull);
      expect(listener.topItem(), isNull);
    });

    test('topItemIndex returns correct index for single visible', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 3, itemTrailingEdge: 0.5, itemLeadingEdge: 0.2),
      ]);
      expect(listener.topItemIndex(), 1); // 3 ~/ 2 = 1
      expect(listener.topItem()?.index, 3);
    });

    test('topItemIndex returns topmost for multiple visible', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 2, itemTrailingEdge: 0.7, itemLeadingEdge: 0.4),
        MockItemPosition(index: 5, itemTrailingEdge: 0.2, itemLeadingEdge: 0.0),
        MockItemPosition(index: 3, itemTrailingEdge: 0.5, itemLeadingEdge: 0.3),
      ]);
      // Only odd indices are elements: 3 and 5. 5 is topmost (smallest trailingEdge > 0)
      expect(listener.topItemIndex(), 2); // 5 ~/ 2 = 2
      expect(listener.topItem()?.index, 5);
    });

    test('topItemIndex ignores non-visible items', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 1, itemTrailingEdge: -0.1, itemLeadingEdge: -0.3),
        MockItemPosition(index: 2, itemTrailingEdge: 0.3, itemLeadingEdge: 0.1),
      ]);
      // Only index 1 is an element, but it's not visible. Should return null.
      expect(listener.topItemIndex(), isNull);
      expect(listener.topItem(), isNull);
    });

    test('topItemIndex returns null when all items are not visible', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 1, itemTrailingEdge: -0.1, itemLeadingEdge: -0.3),
        MockItemPosition(
            index: 2, itemTrailingEdge: -0.3, itemLeadingEdge: -0.5),
        MockItemPosition(
            index: 3, itemTrailingEdge: 0.0, itemLeadingEdge: -0.2),
      ]);
      expect(listener.topItemIndex(), isNull);
      expect(listener.topItem(), isNull);
    });

    test('tiebreaker for items with same trailing edge prefers lower index',
        () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 5, itemTrailingEdge: 0.3, itemLeadingEdge: 0.1),
        MockItemPosition(index: 3, itemTrailingEdge: 0.3, itemLeadingEdge: 0.1),
      ]);
      // Both are elements, trailing edges equal, lower index wins (3)
      expect(listener.topItemIndex(), 1); // 3 ~/ 2 = 1
      expect(listener.topItem()?.index, 3);
    });

    test('items completely off-screen are filtered out', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 2, itemTrailingEdge: 0.7, itemLeadingEdge: 0.5),
        MockItemPosition(index: 5, itemTrailingEdge: 0.2, itemLeadingEdge: 0.0),
        MockItemPosition(
            index: 3,
            itemTrailingEdge: 1.2,
            itemLeadingEdge: 1.0), // Off-screen (past viewport)
        MockItemPosition(
            index: 4,
            itemTrailingEdge: -0.1,
            itemLeadingEdge: -0.3), // Off-screen (before viewport)
      ]);
      // Only 5 is a visible element
      expect(listener.topItemIndex(), 2); // 5 ~/ 2 = 2
      expect(listener.topItem()?.index, 5);
    });
  });

  group('ItemPositionsListenerExt - parameter variations', () {
    test('topItemIndex with reverse=true returns bottommost item', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 2, itemTrailingEdge: 0.7, itemLeadingEdge: 0.5),
        MockItemPosition(index: 5, itemTrailingEdge: 0.2, itemLeadingEdge: 0.0),
        MockItemPosition(index: 3, itemTrailingEdge: 0.9, itemLeadingEdge: 0.7),
      ]);
      // Only odd indices are elements: 3 and 5. In reverse mode, 3 is topmost (largest trailingEdge)
      expect(listener.topItemIndex(reverse: true), 1); // 3 ~/ 2 = 1
      expect(listener.topItem(reverse: true)?.index, 3);
    });

    test('topItemIndex respects horizontal + RTL direction', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 2, itemTrailingEdge: 0.7, itemLeadingEdge: 0.5),
        MockItemPosition(index: 5, itemTrailingEdge: 0.2, itemLeadingEdge: 0.0),
        MockItemPosition(index: 3, itemTrailingEdge: 0.9, itemLeadingEdge: 0.7),
      ]);
      // Only odd indices are elements: 3 and 5. In RTL horizontal mode, 3 is topmost (largest leadingEdge)
      expect(
          listener.topItemIndex(
              scrollDirection: Axis.horizontal,
              textDirection: TextDirection.rtl),
          1); // 3 ~/ 2 = 1
      expect(
          listener
              .topItem(
                  scrollDirection: Axis.horizontal,
                  textDirection: TextDirection.rtl)
              ?.index,
          3);
    });

    test('handles complex combinations of parameters', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 2, itemTrailingEdge: 0.7, itemLeadingEdge: 0.5),
        MockItemPosition(index: 5, itemTrailingEdge: 0.2, itemLeadingEdge: 0.0),
        MockItemPosition(index: 3, itemTrailingEdge: 0.9, itemLeadingEdge: 0.7),
        MockItemPosition(index: 4, itemTrailingEdge: 0.5, itemLeadingEdge: 0.1),
      ]);

      // Only odd indices are elements: 3 and 5. Horizontal + RTL + Reversed + minVisibility
      final result = listener.topItemIndex(
          reverse: true,
          scrollDirection: Axis.horizontal,
          textDirection: TextDirection.rtl,
          minVisibility: 0.2);

      expect(result, 1); // 3 ~/ 2 = 1

      final itemResult = listener.topItem(
          reverse: true,
          scrollDirection: Axis.horizontal,
          textDirection: TextDirection.rtl,
          minVisibility: 0.2);

      expect(itemResult?.index, 3);
    });
  });

  group('ItemPositionsListenerExt - filtering parameters', () {
    test('topItemIndex with minVisibility filters barely visible items', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 3,
            itemTrailingEdge: 0.9,
            itemLeadingEdge: 0.2), // 70% visible, element
        MockItemPosition(
            index: 2,
            itemTrailingEdge: 0.7,
            itemLeadingEdge: 0.5), // 20% visible, separator
        MockItemPosition(
            index: 5,
            itemTrailingEdge: 0.2,
            itemLeadingEdge: 0.0), // 20% visible, element
      ]);
      // With minVisibility = 0.3, only item 3 qualifies (element)
      expect(listener.topItemIndex(minVisibility: 0.3), 1); // 3 ~/ 2 = 1
      expect(listener.topItem(minVisibility: 0.3)?.index, 3);

      // With minVisibility = 0.8, no elements qualify
      expect(listener.topItemIndex(minVisibility: 0.8), isNull);
      expect(listener.topItem(minVisibility: 0.8), isNull);
    });

    test(
        'topItemIndex with minLeadingEdgeVisibility filters items past threshold',
        () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 3,
            itemTrailingEdge: 0.9,
            itemLeadingEdge: 0.6), // Leading edge: 0.6, element
        MockItemPosition(
            index: 2,
            itemTrailingEdge: 0.7,
            itemLeadingEdge: 0.5), // Leading edge: 0.5, separator
        MockItemPosition(
            index: 5,
            itemTrailingEdge: 0.2,
            itemLeadingEdge: 0.0), // Leading edge: 0.0, element
      ]);

      // With minLeadingEdgeVisibility = 0.6, only items with leadingEdge <= 0.6 should be considered
      // Only 3 and 5 are elements, and both qualify, but 5 has smaller trailing edge
      expect(listener.topItemIndex(minLeadingEdgeVisibility: 0.6),
          2); // 5 ~/ 2 = 2
      expect(listener.topItem(minLeadingEdgeVisibility: 0.6)?.index, 5);

      // With minLeadingEdgeVisibility = 0.4, only item 5 qualifies (element)
      expect(listener.topItemIndex(minLeadingEdgeVisibility: 0.4),
          2); // 5 ~/ 2 = 2
      expect(listener.topItem(minLeadingEdgeVisibility: 0.4)?.index, 5);
    });

    test('combines minLeadingEdgeVisibility with other parameters', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 3, itemTrailingEdge: 0.9, itemLeadingEdge: 0.7), // element
        MockItemPosition(
            index: 2, itemTrailingEdge: 0.7, itemLeadingEdge: 0.5), // separator
        MockItemPosition(
            index: 5, itemTrailingEdge: 0.2, itemLeadingEdge: 0.0), // element
      ]);

      // With reverse + minLeadingEdgeVisibility, only elements considered
      expect(
          listener.topItemIndex(reverse: true, minLeadingEdgeVisibility: 0.6),
          2); // 5 ~/ 2 = 2
      expect(
          listener.topItem(reverse: true, minLeadingEdgeVisibility: 0.6)?.index,
          5);
    });
  });

  group('ItemPositionsListenerExt - topSeparatorIndex', () {
    test('topSeparatorIndex returns correct separator index for even indices',
        () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 4,
            itemTrailingEdge: 0.5,
            itemLeadingEdge: 0.2), // separator at logical index 2
      ]);
      expect(listener.topSeparatorIndex(), 2);
    });

    test(
        'returns null if topmost visible item is neither element nor separator',
        () {
      final listener = MockItemPositionsListener([]);
      expect(listener.topSeparatorIndex(), isNull);
    });

    test('topSeparatorIndex with multiple visible items', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 2,
            itemTrailingEdge: 0.7,
            itemLeadingEdge: 0.4), // separator at 1
        MockItemPosition(
            index: 5,
            itemTrailingEdge: 0.2,
            itemLeadingEdge: 0.0), // element at 2
        MockItemPosition(
            index: 3,
            itemTrailingEdge: 0.5,
            itemLeadingEdge: 0.3), // element at 1
      ]);
      // 5 is topmost (smallest trailingEdge > 0), and is an element
      expect(listener.topSeparatorIndex(), isNull);
    });

    test('topSeparatorIndex with topmost visible separator', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 0,
            itemTrailingEdge: 0.2,
            itemLeadingEdge: 0.0), // separator at 0
        MockItemPosition(
            index: 1,
            itemTrailingEdge: 0.5,
            itemLeadingEdge: 0.2), // element at 0
      ]);
      // 0 is a separator, but topItemIndex/topItem should ignore it
      expect(listener.topSeparatorIndex(), 0);
      expect(listener.topItemIndex(),
          0); // topItemIndex returns logical index of first visible element (1 ~/ 2 = 0)
    });
  });
}

/// Mock implementation of ItemPositionsListener for testing
class MockItemPositionsListener implements ItemPositionsListener {
  @override
  final ValueNotifier<Iterable<ItemPosition>> itemPositions;

  MockItemPositionsListener(List<ItemPosition> positions)
      : itemPositions = ValueNotifier<Iterable<ItemPosition>>(positions);
}

/// Mock implementation of ItemPosition for testing
class MockItemPosition implements ItemPosition {
  @override
  final int index;
  @override
  final double itemLeadingEdge;
  @override
  final double itemTrailingEdge;

  MockItemPosition({
    required this.index,
    required this.itemTrailingEdge,
    required this.itemLeadingEdge,
  });

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(covariant ItemPosition other) {
    if (identical(this, other)) return true;
    return other.index == index &&
        other.itemLeadingEdge == itemLeadingEdge &&
        other.itemTrailingEdge == itemTrailingEdge;
  }

  @override
  int get hashCode => Object.hash(index, itemLeadingEdge, itemTrailingEdge);
}
