import '../domain/recommendation_snapshot.dart';
import '../../harvest_case/domain/harvest_case.dart';
import '../../../shared/models/crop.dart';

/// Fixed presentation fixtures, never calculated from farmer inputs.
class MockRecommendationRepository implements RecommendationRepository {
  @override
  Future<RecommendationSnapshot> evaluate(HarvestCase harvestCase) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    return _snapshot(harvestCase, false);
  }

  @override
  Future<RecommendationSnapshot> simulateChange(HarvestCase harvestCase) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _snapshot(harvestCase, true);
  }

  RecommendationSnapshot _snapshot(
    HarvestCase c,
    bool changed,
  ) => RecommendationSnapshot(
    caseId: c.id,
    action: 'Sell today',
    destination: changed
        ? const Destination(
            id: 'riverside',
            name: 'Riverside market',
            distanceKm: 16,
            travelTime: '35 min',
            closesAt: '4:30 PM',
          )
        : const Destination(
            id: 'growers',
            name: 'Growers market',
            distanceKm: 29,
            travelTime: '55 min',
            closesAt: '4:00 PM',
          ),
    expectedNetValue: changed ? '₹12,850' : '₹13,450',
    range: changed ? '₹12,100 – ₹13,400' : '₹12,700 – ₹14,100',
    baselineValue: '₹11,700',
    valueDifference: changed ? '+₹1,150' : '+₹1,750',
    reasons: [
      (
        title: changed
            ? 'A shorter trip in the heat'
            : 'A better estimated return',
        detail: changed
            ? 'The closer destination reduces time on the road for this example batch.'
            : 'The example market offer leaves more value after travel and handling.',
      ),
      (
        title: 'Transport is accounted for',
        detail:
            'Estimated net value includes demo transport and handling costs.',
      ),
      (
        title: 'Your timing comes first',
        detail: 'Same-day sale keeps this example within its selling window.',
      ),
    ],
    assumptions: const [
      'Illustrative fixture for a 650 kg tomato batch; edits do not recalculate these figures.',
      'Market acceptance, buyer availability and prices must be checked before travelling.',
      'No confirmed buyer or transport booking. All amounts are estimates.',
      'This demo uses no live market, weather or routing services.',
    ],
    dataFreshness: 'Synthetic local snapshot • 18 Sep 2026, 9:15 AM',
    alternatives: const [
      RecommendationAlternative(
        action: 'Wait & sell tomorrow',
        destination: 'Village mandi',
        value: '₹10,950',
        status: 'Not advised',
        reason:
            'Waiting exposes ripe produce to overnight quality loss and conflicts with a same-day selling constraint.',
      ),
      RecommendationAlternative(
        action: 'Cold storage · 2 days',
        destination: 'District cold hub',
        value: 'Not feasible',
        status: 'Unavailable',
        reason:
            'No confirmed space for this example batch. Storage fees may outweigh a better selling price.',
      ),
    ],
    temperature: changed ? '33°C' : '28°C',
    humidity: changed ? '61%' : '56%',
    remainingWindow: changed ? '~4.5 hrs' : '~7 hrs',
    marketRates: const [
      (name: 'Growers market · 29 km', price: '₹24.0 /kg'),
      (name: 'Riverside market · 16 km', price: '₹22.5 /kg'),
      (name: 'Village mandi · 8 km', price: '₹20.0 /kg'),
    ],
  );
}
