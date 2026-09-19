import 'package:flutter/material.dart';
import '../../recommendation/presentation/live_recommendation_screen.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const LiveRecommendationScreen(monitor: true);
}
