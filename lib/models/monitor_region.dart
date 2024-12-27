enum MonitorRegion {
  europe(1, 'Europe'),
  oceania(2, 'Oceania'),
  northAmerica(3, 'North America'),
  southAmerica(4, 'South America'),
  africa(5, 'Africa'),
  asia(6, 'Asia'),
  custom(7, 'Custom'),
  custom2(8, 'Custom 2'),
  custom3(9, 'Custom 3'),
  custom4(10, 'Custom 4'),
  custom5(11, 'Custom 5');

  final int id;
  final String name;

  const MonitorRegion(this.id, this.name);

  static MonitorRegion fromId(int id) {
    return MonitorRegion.values.firstWhere(
      (region) => region.id == id,
      orElse: () => MonitorRegion.custom,
    );
  }
}
