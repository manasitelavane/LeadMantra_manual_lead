class CalendarEvent {
  final String id;
  final String note;
  final DateTime? followUpDate;
  final String recurrence;
  final String assignTo;
  final DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.note,
    this.followUpDate,
    this.recurrence = 'Does not repeat',
    this.assignTo = '',
    required this.createdAt,
  });

  CalendarEvent copyWith({
    String? note,
    Object? followUpDate = _keep,
    String? recurrence,
    String? assignTo,
  }) {
    return CalendarEvent(
      id: id,
      note: note ?? this.note,
      followUpDate:
          followUpDate == _keep ? this.followUpDate : followUpDate as DateTime?,
      recurrence: recurrence ?? this.recurrence,
      assignTo: assignTo ?? this.assignTo,
      createdAt: createdAt,
    );
  }

  static const _keep = Object();
}
