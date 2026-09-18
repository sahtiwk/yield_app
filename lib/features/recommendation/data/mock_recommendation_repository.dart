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
  ) {
    // Generate deterministic deterministic values based on quantity
    final double qty = c.quantityKg;
    // Base rate around ₹20/kg
    final double rateGrowers = 24.0;
    final double rateRiverside = 22.5;
    final double rateMandi = 20.0;

    final double transportGrowers = qty * 1.5; // cost to transport to growers
    final double transportRiverside = qty * 0.8; // cost to transport to riverside
    final double transportMandi = qty * 0.2; // cost to mandi

    final netGrowers = (qty * rateGrowers) - transportGrowers;
    final netRiverside = (qty * rateRiverside) - transportRiverside;
    final netMandi = (qty * rateMandi) - transportMandi;

    final bestNet = changed ? netRiverside : netGrowers;
    final baseline = netMandi;
    final difference = bestNet - baseline;
    
    // Formatting helper
    String formatRupees(double v) => '₹${v.toStringAsFixed(0)}';

    return RecommendationSnapshot(
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
      expectedNetValue: formatRupees(bestNet),
      range: '${formatRupees(bestNet * 0.95)} – ${formatRupees(bestNet * 1.05)}',
      baselineValue: formatRupees(baseline),
      valueDifference: '+${formatRupees(difference)}',
      reasons: [
        (
          title: changed
              ? 'A shorter trip in the heat'
              : 'A better estimated return',
          detail: changed
              ? 'The closer destination reduces time on the road for this batch.'
              : 'The example market offer leaves more value after travel and handling.',
        ),
        (
          title: 'Transport is accounted for',
          detail:
              'Estimated net value includes transport and handling costs based on ${qty.toStringAsFixed(0)} kg.',
        ),
        (
          title: 'Your timing comes first',
          detail: 'Same-day sale keeps this batch within its selling window.',
        ),
      ],
      assumptions: [
        'Illustrative fixture for a ${qty.toStringAsFixed(0)} kg ${c.crop.name} batch; dynamically adjusted estimates.',
        'Market acceptance, buyer availability and prices must be checked before travelling.',
        'No confirmed buyer or transport booking. All amounts are estimates.',
        'This demo uses no live market, weather or routing services.',
      ],
      dataFreshness: 'Synthetic local snapshot • ${DateTime.now().toLocal().toString().split('.')[0]}',
      alternatives: [
        RecommendationAlternative(
          action: 'Wait & sell tomorrow',
          destination: 'Village mandi',
          value: formatRupees(baseline * 0.85), // 15% loss
          status: 'Not advised',
          reason:
              'Waiting exposes ripe produce to overnight quality loss and conflicts with a same-day selling constraint.',
        ),
        const RecommendationAlternative(
          action: 'Cold storage · 2 days',
          destination: 'District cold hub',
          value: 'Not feasible',
          status: 'Unavailable',
          reason:
              'No confirmed space for this batch. Storage fees may outweigh a better selling price.',
        ),
      ],
      temperature: changed ? '33°C' : '28°C',
      humidity: changed ? '61%' : '56%',
      remainingWindow: changed ? '~4.5 hrs' : '~7 hrs',
      marketRates: [
        (name: 'Growers market · 29 km', price: '₹${rateGrowers.toStringAsFixed(1)} /kg'),
        (name: 'Riverside market · 16 km', price: '₹${rateRiverside.toStringAsFixed(1)} /kg'),
        (name: 'Village mandi · 8 km', price: '₹${rateMandi.toStringAsFixed(1)} /kg'),
      ],
    );
  }
}
