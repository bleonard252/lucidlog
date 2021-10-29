class PlotPointRecord {
  final String? subtitle;
  final String body;

  PlotPointRecord({this.subtitle, required this.body});

  Map toJSON() => {
    "subtitle": subtitle,
    "body": body,
  };
}