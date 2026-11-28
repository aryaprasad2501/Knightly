import '../../../core/time/calendar_date.dart';
import '../../../core/time/habit_schedule.dart';
import 'insights.dart';

/// How a review line reads: good news, plain fact, or something to watch.
enum ReviewTone { good, neutral, watch }

/// One sentence of the weekly review.
class ReviewLine {
  const ReviewLine(this.text, [this.tone = ReviewTone.neutral]);

  final String text;
  final ReviewTone tone;

  @override
  bool operator ==(Object other) => other is ReviewLine && other.text == text && other.tone == tone;

  @override
  int get hashCode => Object.hash(text, tone);

  @override
  String toString() => 'ReviewLine($text, $tone)';
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// The weekly review: a few plain sentences about the last 7 days, written
/// from [week] (an [InsightPeriod.week] snapshot). Only real figures; an empty
/// week gives an empty review.
List<ReviewLine> weeklyReview(InsightsSnapshot week) {
  if (week.isEmpty) return const [];
  final lines = <ReviewLine>[];

  final score = week.score, prev = week.previousScore;
  if (score != null) {
    if (prev == null) {
      lines.add(ReviewLine('Your score for the week is $score.'));
    } else if (score == prev) {
      lines.add(ReviewLine('Your score held at $score, the same as the week before.'));
    } else {
      final up = score > prev;
      lines.add(
        ReviewLine(
          'Your score is $score, ${up ? 'up' : 'down'} ${(score - prev).abs()} on the week before.',
          up ? ReviewTone.good : ReviewTone.watch,
        ),
      );
    }
  }

  final rated = [
    for (final r in week.rates.values)
      if (r.expected > 0) r,
  ]..sort((a, b) => b.rate.compareTo(a.rate));
  if (rated.isNotEmpty) {
    final best = rated.first;
    lines.add(
      ReviewLine('Strongest area: ${best.area.label} at ${(best.rate * 100).round()}%.', ReviewTone.good),
    );
    final worst = rated.last;
    if (rated.length > 1 && worst.rate < 0.6) {
      lines.add(
        ReviewLine(
          'Needs attention: ${worst.area.label} at ${(worst.rate * 100).round()}%.',
          ReviewTone.watch,
        ),
      );
    }
  }

  if (week.areas.contains(InsightArea.missions) && (week.missionsDone > 0 || week.missionsOverdue > 0)) {
    final done = week.missionsDone == 1 ? '1 mission done' : '${week.missionsDone} missions done';
    lines.add(
      week.missionsOverdue == 0
          ? ReviewLine('$done and nothing overdue.', ReviewTone.good)
          : ReviewLine('$done; ${week.missionsOverdue} overdue now.', ReviewTone.watch),
    );
  }

  final streaks = [...week.habitLines]..sort((a, b) => b.current.compareTo(a.current));
  if (streaks.isNotEmpty && streaks.first.current >= 2) {
    final top = streaks.first;
    final unit = top.inWeeks ? 'weeks' : 'days';
    lines.add(ReviewLine('Longest streak: ${top.name}, ${top.current} $unit in a row.', ReviewTone.good));
  }

  final wins = week.winsInPeriod;
  if (wins > 0) {
    CalendarDate? bestDay;
    var bestCount = 0;
    for (var i = 0; i < 7; i++) {
      final day = week.today.addDays(-i);
      final n = (week.winsByDay[day] ?? const <InsightArea, int>{}).values.fold(0, (a, b) => a + b);
      if (n > bestCount) {
        bestCount = n;
        bestDay = day;
      }
    }
    lines.add(
      ReviewLine(
        bestDay == null
            ? '$wins wins this week.'
            : '$wins wins this week; your best day was ${_weekdays[bestDay.weekday - 1]} with $bestCount.',
      ),
    );
  }
  return lines;
}

/// Habit completion after nights at the sleep goal against after shorter
/// nights, over the last [days] days. Null until there are at least three
/// days on each side (too few to say anything).
({double rested, double short, int restedDays, int shortDays})? sleepVsHabits(
  InsightsInput input, {
  int days = 30,
}) {
  if (!input.areas.contains(InsightArea.sleep) || !input.areas.contains(InsightArea.habits)) return null;
  final from = input.today.addDays(-days);
  final counts = {for (final c in input.checkIns) (c.habitId, c.date): c.count};

  double? completion(CalendarDate d) {
    var expected = 0, done = 0;
    for (final h in input.habits) {
      if (d.isBefore(h.startDate) || h.schedule is TimesPerWeek || !h.schedule.isScheduledOn(d)) continue;
      expected++;
      if ((counts[(h.id, d)] ?? 0) >= h.target) done++;
    }
    return expected == 0 ? null : done / expected;
  }

  final rested = <double>[], short = <double>[];
  for (final night in input.sleep) {
    final d = night.date;
    // Today is still going: only finished days count.
    if (d.isBefore(from) || !d.isBefore(input.today)) continue;
    final c = completion(d);
    if (c == null) continue;
    (night.duration >= input.sleepGoal ? rested : short).add(c);
  }
  if (rested.length < 3 || short.length < 3) return null;
  double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
  return (rested: avg(rested), short: avg(short), restedDays: rested.length, shortDays: short.length);
}

/// The sleep link as a sentence, or null when there is nothing to say.
ReviewLine? sleepVsHabitsLine(InsightsInput input) {
  final r = sleepVsHabits(input);
  if (r == null) return null;
  final rested = (r.rested * 100).round(), short = (r.short * 100).round();
  if ((rested - short).abs() < 10) {
    return const ReviewLine('Sleep and habits: no clear link in the last 30 days.');
  }
  return ReviewLine(
    'On days after a full night you finished $rested% of your habits, against $short% after short nights.',
    rested > short ? ReviewTone.good : ReviewTone.neutral,
  );
}
