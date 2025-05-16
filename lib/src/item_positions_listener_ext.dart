import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Extension to get the topmost visible item index or ItemPosition from ItemPositionsListener.
extension ItemPositionsListenerExt on ItemPositionsListener {
  /// Returns the index of the topmost visible item, or null if none.
  ///
  /// By default, an item is considered visible if its trailing edge is visible
  /// (trailingEdge > 0) and its leading edge is not past the viewport (leadingEdge < 1).
  ///
  /// For horizontal lists with [reverse] = true or RTL text direction, "topmost"
  /// will refer to the rightmost visible item. For vertical lists with [reverse] = true,
  /// it will refer to the bottommost visible item.
  ///
  /// [reverse] - Whether the list is reversed (bottommost/rightmost item is first).
  /// [minVisibility] - Minimum visibility threshold (0-1) for an item to be considered visible.
  ///                  An item must have at least this fraction of its extent visible.
  /// [scrollDirection] - Direction of the list (vertical or horizontal).
  /// [textDirection] - Text direction, relevant for horizontal lists (LTR or RTL).
  /// [minLeadingEdgeVisibility] - Optional minimum leading edge visibility threshold (0-1).
  ///                             If specified, items with leading edge beyond this threshold are ignored.
  int? topItemIndex({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minLeadingEdgeVisibility,
  }) {
    final item = _getTopVisibleItem(
      reverse: reverse,
      minVisibility: minVisibility,
      scrollDirection: scrollDirection,
      textDirection: textDirection,
      minLeadingEdgeVisibility: minLeadingEdgeVisibility,
    );
    return item?.index;
  }

  /// Returns the topmost visible ItemPosition, or null if none.
  ///
  /// By default, an item is considered visible if its trailing edge is visible
  /// (trailingEdge > 0) and its leading edge is not past the viewport (leadingEdge < 1).
  ///
  /// For horizontal lists with [reverse] = true or RTL text direction, "topmost"
  /// will refer to the rightmost visible item. For vertical lists with [reverse] = true,
  /// it will refer to the bottommost visible item.
  ///
  /// [reverse] - Whether the list is reversed (bottommost/rightmost item is first).
  /// [minVisibility] - Minimum visibility threshold (0-1) for an item to be considered visible.
  /// [scrollDirection] - Direction of the list (vertical or horizontal).
  /// [textDirection] - Text direction, relevant for horizontal lists (LTR or RTL).
  /// [minLeadingEdgeVisibility] - Optional minimum leading edge visibility threshold (0-1).
  ///                             If specified, items with leading edge beyond this threshold are ignored.
  ItemPosition? topItem({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minLeadingEdgeVisibility,
  }) {
    return _getTopVisibleItem(
      reverse: reverse,
      minVisibility: minVisibility,
      scrollDirection: scrollDirection,
      textDirection: textDirection,
      minLeadingEdgeVisibility: minLeadingEdgeVisibility,
    );
  }

  /// Internal implementation for both topVisibleItemIndex and topVisibleItem
  ItemPosition? _getTopVisibleItem({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minLeadingEdgeVisibility,
  }) {
    final positions = itemPositions.value;
    if (positions.isEmpty) return null;

    // Filter for visible items with enhanced criteria
    final visible = positions.where((pos) {
      // Item must have its trailing edge visible
      final isTrailingVisible = pos.itemTrailingEdge > 0;

      // Item must have its leading edge not past the viewport
      final isLeadingVisible = pos.itemLeadingEdge < 1;

      // Item must meet minimum leading edge visibility if specified
      final meetsLeadingEdgeThreshold = minLeadingEdgeVisibility == null ||
          pos.itemLeadingEdge <= minLeadingEdgeVisibility;

      // Calculate how much of the item is actually visible in the viewport
      final visibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
              pos.itemLeadingEdge.clamp(0.0, 1.0))
          .clamp(0.0, 1.0);

      // Item must have at least minVisibility of its extent visible
      final hasSufficientVisibility = visibility >= minVisibility;

      return isTrailingVisible &&
          isLeadingVisible &&
          meetsLeadingEdgeThreshold &&
          hasSufficientVisibility;
    });

    if (visible.isEmpty) return null;

    // Determine which edge to use for comparison based on scroll direction and settings
    bool useTrailingEdge = true;
    if (scrollDirection == Axis.horizontal) {
      // For horizontal lists, adjust based on text direction and reverse
      final isRtl = textDirection == TextDirection.rtl;
      useTrailingEdge = !((reverse && !isRtl) || (!reverse && isRtl));
    } else {
      // For vertical lists, adjust based on reverse only
      useTrailingEdge = !reverse;
    }

    // Find the topmost item based on the appropriate edge
    return visible.reduce((candidate, pos) {
      if (useTrailingEdge) {
        // Use trailing edge (default for top-to-bottom/LTR lists)
        if (pos.itemTrailingEdge < candidate.itemTrailingEdge) return pos;
        // If equal trailing edges, use index as tiebreaker (lower index = higher in list)
        if (pos.itemTrailingEdge == candidate.itemTrailingEdge) {
          // If items have same trailing edge, prefer the one with more visibility
          final candidateVisibility =
              (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                      candidate.itemLeadingEdge.clamp(0.0, 1.0))
                  .clamp(0.0, 1.0);
          final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                  pos.itemLeadingEdge.clamp(0.0, 1.0))
              .clamp(0.0, 1.0);

          if (posVisibility > candidateVisibility) return pos;
          if (posVisibility < candidateVisibility) return candidate;

          // If same visibility too, use index as final tiebreaker
          return pos.index < candidate.index ? pos : candidate;
        }
        return candidate;
      } else {
        // Use leading edge (for reversed/RTL lists)
        if (pos.itemLeadingEdge > candidate.itemLeadingEdge) return pos;
        // If equal leading edges, apply similar tiebreaking logic
        if (pos.itemLeadingEdge == candidate.itemLeadingEdge) {
          // If items have same leading edge, prefer the one with more visibility
          final candidateVisibility =
              (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                      candidate.itemLeadingEdge.clamp(0.0, 1.0))
                  .clamp(0.0, 1.0);
          final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                  pos.itemLeadingEdge.clamp(0.0, 1.0))
              .clamp(0.0, 1.0);

          if (posVisibility > candidateVisibility) return pos;
          if (posVisibility < candidateVisibility) return candidate;

          // If same visibility too, use index as final tiebreaker
          return pos.index < candidate.index ? pos : candidate;
        }
        return candidate;
      }
    });
  }
}
