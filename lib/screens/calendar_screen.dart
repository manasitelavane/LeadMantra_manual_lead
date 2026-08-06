import 'package:flutter/material.dart';

import '../core/app_bar.dart';
import '../core/theme.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import 'add_edit_event_screen.dart';
import 'event_list_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _displayed;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayed = DateTime(now.year, now.month);
    _selected = DateTime(now.year, now.month, now.day);
    CalendarService.instance.loadDropdowns();
    CalendarService.instance.loadMonthGrid(_displayed);
    CalendarService.instance.loadNotesForDate(_selected);
  }

  void _prevMonth() {
    final m = DateTime(_displayed.year, _displayed.month - 1);
    setState(() => _displayed = m);
    CalendarService.instance.loadMonthGrid(m);
  }

  void _nextMonth() {
    final m = DateTime(_displayed.year, _displayed.month + 1);
    setState(() => _displayed = m);
    CalendarService.instance.loadMonthGrid(m);
  }

  void _onNoteChanged() {
    CalendarService.instance.loadMonthGrid(_displayed);
    CalendarService.instance.loadNotesForDate(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: LeadMantraAppBar(
        title: 'Your Calendar',
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: AppTheme.primary),
            tooltip: 'View All Notes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventListScreen()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: CalendarService.instance,
        builder: (context, _) {
          return Column(
            children: [
              // ── Calendar card ─────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _MonthHeader(
                      displayed: _displayed,
                      onPrev: _prevMonth,
                      onNext: _nextMonth,
                    ),
                    const SizedBox(height: 12),
                    const _DayHeaders(),
                    const SizedBox(height: 4),
                    _CalendarGrid(
                      displayed: _displayed,
                      selected: _selected,
                      onDayTap: (d) {
                        setState(() => _selected = d);
                        CalendarService.instance.loadNotesForDate(d);
                      },
                    ),
                    if (CalendarService.instance.isLoadingGrid)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Notes for selected day ────────────────────────────────────
              Expanded(
                child: _SelectedDayPanel(
                  date: _selected,
                  onAddTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditEventScreen(initialDate: _selected),
                      ),
                    );
                    if (mounted) _onNoteChanged();
                  },
                  onNoteChanged: _onNoteChanged,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditEventScreen(initialDate: _selected),
            ),
          );
          if (mounted) _onNoteChanged();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ── Month header ──────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader(
      {required this.displayed, required this.onPrev, required this.onNext});

  final DateTime displayed;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              size: 24, color: AppTheme.primary),
          onPressed: onPrev,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        Expanded(
          child: Text(
            '${_months[displayed.month - 1]} ${displayed.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded,
              size: 24, color: AppTheme.primary),
          onPressed: onNext,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

// ── Day headers ───────────────────────────────────────────────────────────────

class _DayHeaders extends StatelessWidget {
  const _DayHeaders();

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _days
          .map(
            (d) => Expanded(
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.displayed,
    required this.selected,
    required this.onDayTap,
  });

  final DateTime displayed;
  final DateTime selected;
  final void Function(DateTime) onDayTap;

  @override
  Widget build(BuildContext context) {
    final year = displayed.year;
    final month = displayed.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final today = DateTime.now();

    final cells = <Widget>[];

    final prevMonthDays = DateTime(year, month, 0).day;
    for (int i = firstWeekday - 1; i >= 0; i--) {
      cells.add(_GreyDayCell(day: prevMonthDays - i));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day;

      final dayData = CalendarService.instance.getDayData(date);
      final hasEvents = (dayData?['total'] as int? ?? 0) > 0;
      final isOverdue = dayData?['has_overdue'] as bool? ?? false;

      cells.add(_DayCell(
        day: day,
        isToday: isToday,
        isSelected: isSelected,
        hasEvents: hasEvents,
        isOverdue: isOverdue,
        onTap: () => onDayTap(date),
      ));
    }

    final totalCells = firstWeekday + daysInMonth;
    final trailingCount = totalCells % 7 == 0 ? 0 : 7 - (totalCells % 7);
    for (int i = 1; i <= trailingCount; i++) {
      cells.add(_GreyDayCell(day: i));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      children: cells,
    );
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEvents,
    required this.isOverdue,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;
  final bool isOverdue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    Color textColor = Colors.black87;

    if (isToday) {
      bgColor = AppTheme.primary;
      textColor = Colors.white;
    } else if (isSelected) {
      bgColor = AppTheme.primary.withValues(alpha: 0.12);
      textColor = AppTheme.primary;
    }

    final dotColor = isOverdue
        ? Colors.red.shade400
        : (isToday ? Colors.white70 : AppTheme.accent);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: bgColor != null
                ? BoxDecoration(color: bgColor, shape: BoxShape.circle)
                : null,
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
          if (hasEvents)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Grey day cell (prev / next month) ────────────────────────────────────────

class _GreyDayCell extends StatelessWidget {
  const _GreyDayCell({required this.day});
  final int day;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$day',
        style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
      ),
    );
  }
}

// ── Selected day panel ────────────────────────────────────────────────────────

class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({
    required this.date,
    required this.onAddTap,
    required this.onNoteChanged,
  });

  final DateTime date;
  final VoidCallback onAddTap;
  final VoidCallback onNoteChanged;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final svc = CalendarService.instance;
    final notes = svc.getNotesForDate(date);
    final isLoading = svc.isLoadingNotes;
    final hasError = svc.notesError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAddTap,
                icon: const Icon(Icons.add_rounded,
                    size: 16, color: AppTheme.primary),
                label: const Text('Add Note',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (isLoading && notes.isEmpty)
          const Expanded(
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primary),
              ),
            ),
          )
        else if (hasError && notes.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                svc.notesError!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ),
          )
        else if (notes.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No notes on this day',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: notes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _DayNoteTile(
                event: notes[i],
                onNoteChanged: onNoteChanged,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Day note tile ─────────────────────────────────────────────────────────────

class _DayNoteTile extends StatelessWidget {
  const _DayNoteTile({
    required this.event,
    required this.onNoteChanged,
  });

  final CalendarEvent event;
  final VoidCallback onNoteChanged;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Note',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this note?',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await CalendarService.instance.deleteNote(event.id);
    if (result.success) {
      onNoteChanged();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to delete note'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  static const _statusColors = {
    'done':      Color(0xFF22C55E),
    'cancelled': Color(0xFF94A3B8),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColors[event.status] ?? const Color(0xFF3B82F6);
    final recurrenceLabel =
        CalendarService.instance.recurrenceLabel(event.recurrence);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.10), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.note,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.recurrence != 'none') ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 11, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(recurrenceLabel,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Edit button
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditEventScreen(event: event),
                ),
              );
              onNoteChanged();
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 14, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 6),
          // Delete button
          GestureDetector(
            onTap: () => _delete(context),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  size: 14, color: Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }
}
