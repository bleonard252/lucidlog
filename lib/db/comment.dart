class DreamCommentRecord {
  final String body;
  late final DateTime timestamp;

  DreamCommentRecord({
    required this.body,
    dynamic timestamp
  }) {
    if (timestamp is DateTime) this.timestamp = timestamp;
    else if (timestamp is int) this.timestamp = DateTime.fromMillisecondsSinceEpoch(timestamp);
    else throw UnsupportedError("Type of timestamp not supported. Must be DateTime or int");
  }
}