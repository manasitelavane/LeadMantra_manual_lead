class CalendarEvent {
  final String id;
  final String note;
  final DateTime? followUpDate;
  final String recurrence;   // API value: 'none' | 'daily' | 'weekly' | 'monthly' | 'quarterly' | 'yearly'
  final int? assigneeId;
  final String assigneeName;
  final String status;       // 'pending' | 'done' | 'cancelled'
  final bool isOverdue;
  final bool isToday;
  final DateTime createdAt;

  const CalendarEvent({
    required this.id,
    required this.note,
    this.followUpDate,
    this.recurrence = 'none',
    this.assigneeId,
    this.assigneeName = '',
    this.status = 'pending',
    this.isOverdue = false,
    this.isToday = false,
    required this.createdAt,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final assignedTo = json['assigned_to'] as Map<String, dynamic>?;
    final dateStr = json['date'] as String?;
    final createdAtStr = json['created_at'] as String?;
    return CalendarEvent(
      id: json['id'].toString(),
      note: json['note'] as String? ?? '',
      followUpDate: dateStr != null ? DateTime.tryParse(dateStr) : null,
      recurrence: json['recur_interval'] as String? ?? 'none',
      assigneeId: assignedTo?['id'] as int?,
      assigneeName: assignedTo?['name'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      isOverdue: json['is_overdue'] as bool? ?? false,
      isToday: json['is_today'] as bool? ?? false,
      createdAt: createdAtStr != null
          ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CalendarEvent copyWith({
    String? note,
    Object? followUpDate = _keep,
    String? recurrence,
    Object? assigneeId = _keep,
    String? assigneeName,
    String? status,
  }) {
    return CalendarEvent(
      id: id,
      note: note ?? this.note,
      followUpDate:
          followUpDate == _keep ? this.followUpDate : followUpDate as DateTime?,
      recurrence: recurrence ?? this.recurrence,
      assigneeId: assigneeId == _keep ? this.assigneeId : assigneeId as int?,
      assigneeName: assigneeName ?? this.assigneeName,
      status: status ?? this.status,
      isOverdue: isOverdue,
      isToday: isToday,
      createdAt: createdAt,
    );
  }

  static const _keep = Object();
}
