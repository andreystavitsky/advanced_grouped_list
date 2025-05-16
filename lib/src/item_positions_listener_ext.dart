import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Extension to get the topmost visible item index or ItemPosition from ItemPositionsListener.
extension ItemPositionsListenerExt on ItemPositionsListener {
  /// Returns the index of the topmost visible item, or null if none.
  int? get topVisibleItemIndex {
    final positions = itemPositions.value;
    if (positions.isEmpty) return null;
    final visible = positions.where((pos) => pos.itemTrailingEdge > 0);
    if (visible.isEmpty) return null;
    final top = visible.reduce(
        (min, pos) => pos.itemTrailingEdge < min.itemTrailingEdge ? pos : min);
    return top.index;
  }

  /// Returns the topmost visible ItemPosition, or null if none.
  ItemPosition? get topVisibleItem {
    final positions = itemPositions.value;
    if (positions.isEmpty) return null;
    final visible = positions.where((pos) => pos.itemTrailingEdge > 0);
    if (visible.isEmpty) return null;
    return visible.reduce(
        (min, pos) => pos.itemTrailingEdge < min.itemTrailingEdge ? pos : min);
  }
}
