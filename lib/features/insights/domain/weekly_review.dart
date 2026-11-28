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
  final completion = _habitCompletion(input);

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
  return (rested: _avg(rested), short: _avg(short), restedDays: rested.length, shortDays: short.length);
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

/// Share of scheduled habits done on a day, or null when none were due.
double? Function(CalendarDate) _habitCompletion(InsightsInput input) {
  final counts = {for (final c in input.checkIns) (c.habitId, c.date): c.count};
  return (d) {
    var expected = 0, done = 0;
    for (final h in input.habits) {
      if (d.isBefore(h.startDate) || h.schedule is TimesPerWeek || !h.schedule.isScheduledOn(d)) continue;
      expected++;
      if ((counts[(h.id, d)] ?? 0) >= h.target) done++;
    }
    return expected == 0 ? null : done / expected;
  };
}

double _avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;

/// Average sleep (hours) after days with a finished workout against after
/// rest days, over the last [days] nights. Null with fewer than three
/// nights on either side.
({double afterWorkout, double afterRest})? workoutVsSleep(InsightsInput input, {int days = 60}) {
  if (!input.areas.contains(InsightArea.workouts) || !input.areas.contains(InsightArea.sleep)) return null;
  final trained = {
    for (final w in input.workouts)
      if (w.finishedAt != null) CalendarDate.of(w.startedAt),
  };
  final from = input.today.addDays(-days);
  final after = <double>[], rest = <double>[];
  for (final night in input.sleep) {
    if (night.date.isBefore(from) || night.date.isAfter(input.today)) continue;
    final hours = night.duration.inMinutes / 60;
    if (hours <= 0) continue;
    (trained.contains(night.date.addDays(-1)) ? after : rest).add(hours);
  }
  if (after.length < 3 || rest.length < 3) return null;
  return (afterWorkout: _avg(after), afterRest: _avg(rest));
}

ReviewLine? workoutVsSleepLine(InsightsInput input) {
  final r = workoutVsSleep(input);
  if (r == null) return null;
  String h(double v) => '${v.toStringAsFixed(1)} h';
  if ((r.afterWorkout - r.afterRest).abs() < 0.25) {
    return const ReviewLine('Workouts and sleep: you sleep about the same after training and rest days.');
  }
  return ReviewLine(
    'After workout days you slept ${h(r.afterWorkout)}, against ${h(r.afterRest)} after rest days.',
    r.afterWorkout > r.afterRest ? ReviewTone.good : ReviewTone.neutral,
  );
}

/// Habit completion on days you reached your water goal against days you
/// didn't, over the last [days] finished days. Null with fewer than three
/// days on either side.
({double hydrated, double dry})? waterVsHabits(InsightsInput input, {int days = 30}) {
  if (!input.areas.contains(InsightArea.water) || !input.areas.contains(InsightArea.habits)) return null;
  final totals = <CalendarDate, int>{};
  for (final w in input.water) {
    totals[w.date] = (totals[w.date] ?? 0) + w.amountMl;
  }
  final completion = _habitCompletion(input);
  final hydrated = <double>[], dry = <double>[];
  for (var i = 1; i <= days; i++) {
    final d = input.today.addDays(-i);
    final total = totals[d];
    if (total == null) continue; // nothing logged: not a data point
    final c = completion(d);
    if (c == null) continue;
    (total >= input.waterGoalMl ? hydrated : dry).add(c);
  }
  if (hydrated.length < 3 || dry.length < 3) return null;
  return (hydrated: _avg(hydrated), dry: _avg(dry));
}

ReviewLine? waterVsHabitsLine(InsightsInput input) {
  final r = waterVsHabits(input);
  if (r == null) return null;
  final a = (r.hydrated * 100).round(), b = (r.dry * 100).round();
  if ((a - b).abs() < 10) return null;
  return ReviewLine(
    'On days you reached your water goal you finished $a% of your habits, against $b% on other days.',
    a > b ? ReviewTone.good : ReviewTone.neutral,
  );
}
