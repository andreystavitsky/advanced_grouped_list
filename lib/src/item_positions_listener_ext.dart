import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Extension to get the topmost visible item index or ItemPosition from ItemPositionsListener.
extension ItemPositionsListenerExt on ItemPositionsListener {
  /// Returns the index of the topmost visible element (not separator) in the logical elements list, or null if none.
  ///
  /// This always returns the index in the elements list (i.e., [rawIndex] ~/ 2),
  /// or null if no element is visible.
  int? topItemIndex({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minLeadingEdgeVisibility,
  }) {
    final item = _getTopVisibleElement(
      reverse: reverse,
      minVisibility: minVisibility,
      scrollDirection: scrollDirection,
      textDirection: textDirection,
      minLeadingEdgeVisibility: minLeadingEdgeVisibility,
    );
    return item != null ? item.index ~/ 2 : null;
  }

  /// Returns the ItemPosition of the topmost visible element (not separator), or null if none is visible.
  ///
  /// This always returns the ItemPosition for an element (odd index), or null if no element is visible.
  ItemPosition? topItem({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minLeadingEdgeVisibility,
  }) {
    return _getTopVisibleElement(
      reverse: reverse,
      minVisibility: minVisibility,
      scrollDirection: scrollDirection,
      textDirection: textDirection,
      minLeadingEdgeVisibility: minLeadingEdgeVisibility,
    );
  }

  /// Returns the index of the topmost visible separator in the widget list, or null if none.
  ///
  /// This always returns the index in the separators list (i.e., [rawIndex] ~/ 2),
  /// or null if the topmost visible item is not a separator.
  int? topSeparatorIndex({
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
    if (item == null) return null;
    // Even indices are separators (0, 2, 4, ...)
    if (item.index % 2 == 0) {
      return item.index ~/ 2;
    }
    return null;
  }

  /// Internal implementation for finding the topmost visible element (odd index).
  ItemPosition? _getTopVisibleElement({
    bool reverse = false,
    double minVisibility = 0.0,
    Axis scrollDirection = Axis.vertical,
    TextDirection textDirection = TextDirection.ltr,
    double? minLeadingEdgeVisibility,
  }) {
    final positions = itemPositions.value;
    if (positions.isEmpty) return null;
    // Only consider elements (odd indices)
    final elementPositions = positions.where((pos) => pos.index % 2 == 1);
    if (elementPositions.isEmpty) return null;
    // Use the same logic as _getTopVisibleItem for filtering and picking the topmost
    final visible = elementPositions.where((pos) {
      final isTrailingVisible = pos.itemTrailingEdge > 0;
      final isLeadingVisible = pos.itemLeadingEdge < 1;
      final meetsLeadingEdgeThreshold = minLeadingEdgeVisibility == null ||
          pos.itemLeadingEdge <= minLeadingEdgeVisibility;
      final visibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
              pos.itemLeadingEdge.clamp(0.0, 1.0))
          .clamp(0.0, 1.0);
      final hasSufficientVisibility = visibility >= minVisibility;
      return isTrailingVisible &&
          isLeadingVisible &&
          meetsLeadingEdgeThreshold &&
          hasSufficientVisibility;
    });
    if (visible.isEmpty) return null;
    bool useTrailingEdge = true;
    if (scrollDirection == Axis.horizontal) {
      final isRtl = textDirection == TextDirection.rtl;
      useTrailingEdge = !((reverse && !isRtl) || (!reverse && isRtl));
    } else {
      useTrailingEdge = !reverse;
    }
    return visible.reduce((candidate, pos) {
      if (useTrailingEdge) {
        if (reverse) {
          // For reverse, pick the one with the largest trailingEdge
          if (pos.itemTrailingEdge > candidate.itemTrailingEdge) return pos;
          if (pos.itemTrailingEdge == candidate.itemTrailingEdge) {
            final candidateVisibility =
                (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                        candidate.itemLeadingEdge.clamp(0.0, 1.0))
                    .clamp(0.0, 1.0);
            final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                    pos.itemLeadingEdge.clamp(0.0, 1.0))
                .clamp(0.0, 1.0);
            if (posVisibility > candidateVisibility) return pos;
            if (posVisibility < candidateVisibility) return candidate;
            return pos.index < candidate.index ? pos : candidate;
          }
          return candidate;
        } else {
          // For normal, pick the one with the smallest trailingEdge
          if (pos.itemTrailingEdge < candidate.itemTrailingEdge) return pos;
          if (pos.itemTrailingEdge == candidate.itemTrailingEdge) {
            final candidateVisibility =
                (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                        candidate.itemLeadingEdge.clamp(0.0, 1.0))
                    .clamp(0.0, 1.0);
            final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                    pos.itemLeadingEdge.clamp(0.0, 1.0))
                .clamp(0.0, 1.0);
            if (posVisibility > candidateVisibility) return pos;
            if (posVisibility < candidateVisibility) return candidate;
            return pos.index < candidate.index ? pos : candidate;
          }
          return candidate;
        }
      } else {
        if (pos.itemLeadingEdge > candidate.itemLeadingEdge) return pos;
        if (pos.itemLeadingEdge == candidate.itemLeadingEdge) {
          final candidateVisibility =
              (candidate.itemTrailingEdge.clamp(0.0, 1.0) -
                      candidate.itemLeadingEdge.clamp(0.0, 1.0))
                  .clamp(0.0, 1.0);
          final posVisibility = (pos.itemTrailingEdge.clamp(0.0, 1.0) -
                  pos.itemLeadingEdge.clamp(0.0, 1.0))
              .clamp(0.0, 1.0);
          if (posVisibility > candidateVisibility) return pos;
          if (posVisibility < candidateVisibility) return candidate;
          return pos.index < candidate.index ? pos : candidate;
        }
        return candidate;
      }
    });
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
