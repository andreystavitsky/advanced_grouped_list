// ignore_for_file: avoid_implementing_value_types, invalid_override_of_non_virtual_member
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';

void main() {
  group('ItemPositionsListenerExt', () {
    test('topVisibleItemIndex returns null for empty', () {
      final listener = _FakeItemPositionsListener([]);
      expect(listener.topVisibleItemIndex, isNull);
      expect(listener.topVisibleItem, isNull);
    });

    test('topVisibleItemIndex returns correct index for single visible', () {
      final listener = _FakeItemPositionsListener([
        _FakeItemPosition(index: 3, itemTrailingEdge: 0.5),
      ]);
      expect(listener.topVisibleItemIndex, 3);
      expect(listener.topVisibleItem?.index, 3);
    });

    test('topVisibleItemIndex returns topmost for multiple visible', () {
      final listener = _FakeItemPositionsListener([
        _FakeItemPosition(index: 2, itemTrailingEdge: 0.7),
        _FakeItemPosition(index: 5, itemTrailingEdge: 0.2),
        _FakeItemPosition(index: 3, itemTrailingEdge: 0.5),
      ]);
      // 5 is topmost (smallest trailingEdge > 0)
      expect(listener.topVisibleItemIndex, 5);
      expect(listener.topVisibleItem?.index, 5);
    });

    test('topVisibleItemIndex ignores non-visible', () {
      final listener = _FakeItemPositionsListener([
        _FakeItemPosition(index: 1, itemTrailingEdge: -0.1),
        _FakeItemPosition(index: 2, itemTrailingEdge: 0.3),
      ]);
      expect(listener.topVisibleItemIndex, 2);
      expect(listener.topVisibleItem?.index, 2);
    });

    test('topVisibleItemIndex returns null when all items are not visible', () {
      final listener = _FakeItemPositionsListener([
        _FakeItemPosition(index: 1, itemTrailingEdge: -0.1),
        _FakeItemPosition(index: 2, itemTrailingEdge: -0.3),
        _FakeItemPosition(index: 3, itemTrailingEdge: 0.0),
      ]);
      expect(listener.topVisibleItemIndex, isNull);
      expect(listener.topVisibleItem, isNull);
    });
  });
}

class _FakeItemPositionsListener implements ItemPositionsListener {
  @override
  final ValueNotifier<Iterable<ItemPosition>> itemPositions;
  _FakeItemPositionsListener(List<ItemPosition> positions)
      : itemPositions = ValueNotifier<Iterable<ItemPosition>>(positions);
}

class _FakeItemPosition implements ItemPosition {
  @override
  final int index;
  @override
  final double itemLeadingEdge;
  @override
  final double itemTrailingEdge;
  _FakeItemPosition({
    required this.index,
    required this.itemTrailingEdge,
  }) : itemLeadingEdge = 0.0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
