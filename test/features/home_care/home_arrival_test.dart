import 'package:flutter_test/flutter_test.dart';
import 'package:knightly/features/home_care/data/home_arrival.dart';

void main() {
  test('the welcome-home message lists what is due, or stays quiet', () {
    expect(HomeArrival.message(const []), isNull);
    expect(HomeArrival.message(const ['Water the plants']), ('Welcome home — 1 job due', 'Water the plants'));
    final many = HomeArrival.message(const ['A', 'B', 'C', 'D', 'E'])!;
    expect(many.$1, 'Welcome home — 5 jobs due');
    expect(many.$2, 'A, B, C +2 more');
  });
}
