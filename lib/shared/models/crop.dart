class Crop {
  const Crop({required this.id, required this.name, required this.variety});
  final String id;
  final String name;
  final String variety;
}

class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.travelTime,
    required this.closesAt,
  });
  final String id;
  final String name;
  final double distanceKm;
  final String travelTime;
  final String closesAt;
}
