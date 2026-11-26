import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/theme/theme_context.dart';
import '../../../../core/design/tokens/k_spacing.dart';
import '../../domain/calendar_event.dart';
import '../event_editor_sheet.dart';
import 'day_agenda.dart';

/// Hour lines with timed occurrences placed by start and length.
/// Overlapping occurrences share the width in columns.
class DayTimeline extends StatelessWidget {
  const DayTimeline({super.key, required this.occurrences});

  /// Timed occurrences of one day.
  final List<EventOccurrence> occurrences;

  static const hourHeight = 56.0;
  static const _labelWidth = 44.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final timed = occurrences.where((o) => o.time != null).toList();
    // 6:00–23:00 by default, widened to fit everything.
    final firstHour = math.min(6, timed.isEmpty ? 6 : timed.map((o) => o.time!.hour).reduce(math.min));
    final lastHour = math
        .max(23, timed.isEmpty ? 23 : timed.map((o) => (o.endTime!.inMinutes / 60).ceil()).reduce(math.max))
        .clamp(firstHour + 1, 24);
    final height = (lastHour - firstHour) * hourHeight;
    final columns = _columns(timed);

    return LayoutBuilder(
      builder: (context, constraints) {
        final laneWidth = constraints.maxWidth - _labelWidth - KSpacing.sm;
        return SizedBox(
          height: height + KSpacing.lg,
          child: Stack(
            children: [
              for (var h = firstHour; h <= lastHour; h++) ...[
                Positioned(
                  left: 0,
                  top: (h - firstHour) * hourHeight,
                  width: _labelWidth,
                  child: ExcludeSemantics(
                    child: Text(
                      '${h.toString().padLeft(2, '0')}:00',
                      style: text.labelSmall?.copyWith(color: p.textMuted),
                    ),
                  ),
                ),
                Positioned(
                  left: _labelWidth + KSpacing.sm,
                  right: 0,
                  top: (h - firstHour) * hourHeight + 7,
                  child: Container(height: KStroke.hairline, color: p.outline),
                ),
              ],
              for (final o in timed)
                () {
                  final (col, cols) = columns[o]!;
                  final start = o.time!.inMinutes - firstHour * 60;
                  final minutes = math.max(o.endTime!.inMinutes - o.time!.inMinutes, 25);
                  final width = laneWidth / cols;
                  return Positioned(
                    left: _labelWidth + KSpacing.sm + col * width,
                    top: start / 60 * hourHeight + 8,
                    width: width - 2,
                    height: minutes / 60 * hourHeight - 2,
                    child: _Block(occurrence: o),
                  );
                }(),
            ],
          ),
        );
      },
    );
  }

  /// Greedy column assignment for overlapping occurrences: (column, columns
  /// in its overlap group).
  static Map<EventOccurrence, (int, int)> _columns(List<EventOccurrence> timed) {
    final sorted = [...timed]..sort((a, b) => a.time!.compareTo(b.time!));
    final result = <EventOccurrence, (int, int)>{};
    var group = <EventOccurrence>[];
    var groupEnd = -1;
    final columnEnds = <int>[];

    void closeGroup() {
      final cols = math.max(1, columnEnds.length);
      for (final o in group) {
        result[o] = (result[o]!.$1, cols);
      }
      group = [];
      columnEnds.clear();
    }

    for (final o in sorted) {
      final start = o.time!.inMinutes;
      final end = o.endTime!.inMinutes;
      if (group.isNotEmpty && start >= groupEnd) closeGroup();
      var col = columnEnds.indexWhere((e) => e <= start);
      if (col == -1) {
        col = columnEnds.length;
        columnEnds.add(end);
      } else {
        columnEnds[col] = end;
      }
      result[o] = (col, 1);
      group.add(o);
      groupEnd = math.max(groupEnd, end);
    }
    if (group.isNotEmpty) closeGroup();
    return result;
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.occurrence});

  final EventOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.textStyles;
    final o = occurrence;
    return Semantics(
      container: true,
      button: true,
      label: '${o.event.title}, ${occurrenceTimeLabel(context, o)}',
      excludeSemantics: true,
      onTap: () => showEventEditor(context, event: o.event, occurrence: o),
      child: GestureDetector(
        onTap: () => showEventEditor(context, event: o.event, occurrence: o),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: KSpacing.sm, vertical: KSpacing.xxs),
          decoration: BoxDecoration(
            // Opaque, so lines behind never show through the block.
            color: o.done ? p.surfaceRaised : Color.alphaBlend(p.accentMuted, p.surfaceRaised),
            borderRadius: BorderRadius.circular(KRadius.sm),
            border: Border(left: BorderSide(color: o.done ? p.textMuted : p.accent, width: 3)),
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  o.event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(color: o.done ? p.textMuted : p.textPrimary),
                ),
                Flexible(
                  child: Text(
                    occurrenceTimeLabel(context, o),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(color: p.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
