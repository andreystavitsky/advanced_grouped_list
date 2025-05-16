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
      expect(listener.topItemIndex(), 3);
      expect(listener.topItem()?.index, 3);
    });

    test('topItemIndex returns topmost for multiple visible', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 2, itemTrailingEdge: 0.7, itemLeadingEdge: 0.4),
        MockItemPosition(index: 5, itemTrailingEdge: 0.2, itemLeadingEdge: 0.0),
        MockItemPosition(index: 3, itemTrailingEdge: 0.5, itemLeadingEdge: 0.3),
      ]);
      // 5 is topmost (smallest trailingEdge > 0)
      expect(listener.topItemIndex(), 5);
      expect(listener.topItem()?.index, 5);
    });

    test('topItemIndex ignores non-visible items', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 1, itemTrailingEdge: -0.1, itemLeadingEdge: -0.3),
        MockItemPosition(index: 2, itemTrailingEdge: 0.3, itemLeadingEdge: 0.1),
      ]);
      expect(listener.topItemIndex(), 2);
      expect(listener.topItem()?.index, 2);
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
        MockItemPosition(index: 2, itemTrailingEdge: 0.3, itemLeadingEdge: 0.1),
      ]);
      // When trailing edges are equal, the item with the lower index should win
      expect(listener.topItemIndex(), 2);
      expect(listener.topItem()?.index, 2);
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

      // Should ignore items 3 and 4 as they are off-screen
      expect(listener.topItemIndex(), 5);
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
      // In reverse mode, 3 is "topmost" (largest trailingEdge)
      expect(listener.topItemIndex(reverse: true), 3);
      expect(listener.topItem(reverse: true)?.index, 3);
    });

    test('topItemIndex respects horizontal + RTL direction', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 2, itemTrailingEdge: 0.7, itemLeadingEdge: 0.5),
        MockItemPosition(index: 5, itemTrailingEdge: 0.2, itemLeadingEdge: 0.0),
        MockItemPosition(index: 3, itemTrailingEdge: 0.9, itemLeadingEdge: 0.7),
      ]);
      // In RTL horizontal mode, 3 is "topmost" (largest leadingEdge)
      expect(
          listener.topItemIndex(
              scrollDirection: Axis.horizontal,
              textDirection: TextDirection.rtl),
          3);
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

      // Horizontal + RTL + Reversed + minVisibility
      final result = listener.topItemIndex(
          reverse: true,
          scrollDirection: Axis.horizontal,
          textDirection: TextDirection.rtl,
          minVisibility: 0.2);

      expect(result, 5);

      final itemResult = listener.topItem(
          reverse: true,
          scrollDirection: Axis.horizontal,
          textDirection: TextDirection.rtl,
          minVisibility: 0.2);

      expect(itemResult?.index, 5);
    });
  });

  group('ItemPositionsListenerExt - filtering parameters', () {
    test('topItemIndex with minVisibility filters barely visible items', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 2,
            itemTrailingEdge: 0.7,
            itemLeadingEdge: 0.5), // 20% visible
        MockItemPosition(
            index: 5,
            itemTrailingEdge: 0.2,
            itemLeadingEdge: 0.0), // 20% visible
        MockItemPosition(
            index: 3,
            itemTrailingEdge: 0.9,
            itemLeadingEdge: 0.2), // 70% visible
      ]);
      // With minVisibility = 0.3, only item 3 qualifies
      expect(listener.topItemIndex(minVisibility: 0.3), 3);
      expect(listener.topItem(minVisibility: 0.3)?.index, 3);

      // With minVisibility = 0.8, no items qualify
      expect(listener.topItemIndex(minVisibility: 0.8), isNull);
      expect(listener.topItem(minVisibility: 0.8), isNull);
    });

    test(
        'topItemIndex with minLeadingEdgeVisibility filters items past threshold',
        () {
      final listener = MockItemPositionsListener([
        MockItemPosition(
            index: 2,
            itemTrailingEdge: 0.7,
            itemLeadingEdge: 0.5), // Leading edge: 0.5
        MockItemPosition(
            index: 5,
            itemTrailingEdge: 0.2,
            itemLeadingEdge: 0.0), // Leading edge: 0.0
        MockItemPosition(
            index: 3,
            itemTrailingEdge: 0.9,
            itemLeadingEdge: 0.6), // Leading edge: 0.6
      ]);

      // With minLeadingEdgeVisibility = 0.6, only items with leadingEdge <= 0.6 should be considered
      // Items with index 2 and 5 qualify, and 5 has smaller trailing edge
      expect(listener.topItemIndex(minLeadingEdgeVisibility: 0.6), 5);
      expect(listener.topItem(minLeadingEdgeVisibility: 0.6)?.index, 5);

      // With minLeadingEdgeVisibility = 0.4, all items with leadingEdge <= 0.4 qualify
      // Only item 5 qualifies, as it has leadingEdge = 0.0
      expect(listener.topItemIndex(minLeadingEdgeVisibility: 0.4), 5);
      expect(listener.topItem(minLeadingEdgeVisibility: 0.4)?.index, 5);
    });

    test('combines minLeadingEdgeVisibility with other parameters', () {
      final listener = MockItemPositionsListener([
        MockItemPosition(index: 2, itemTrailingEdge: 0.7, itemLeadingEdge: 0.5),
        MockItemPosition(index: 5, itemTrailingEdge: 0.2, itemLeadingEdge: 0.0),
        MockItemPosition(index: 3, itemTrailingEdge: 0.9, itemLeadingEdge: 0.7),
      ]);

      // With reverse + minLeadingEdgeVisibility
      expect(
          listener.topItemIndex(reverse: true, minLeadingEdgeVisibility: 0.6),
          2);
      expect(
          listener.topItem(reverse: true, minLeadingEdgeVisibility: 0.6)?.index,
          2);
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
