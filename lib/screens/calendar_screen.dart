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
  }

  void _prevMonth() =>
      setState(() => _displayed = DateTime(_displayed.year, _displayed.month - 1));

  void _nextMonth() =>
      setState(() => _displayed = DateTime(_displayed.year, _displayed.month + 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: LeadMantraAppBar(
        title: 'Your Calendar',
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: AppTheme.primary),
            tooltip: 'View All Events',
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
              // ── Calendar card ──────────────────────────────────────
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
                      onDayTap: (d) => setState(() => _selected = d),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Events for selected day ────────────────────────────
              Expanded(
                child: _SelectedDayPanel(
                  date: _selected,
                  onAddTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddEditEventScreen(initialDate: _selected),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddEditEventScreen(initialDate: _selected),
          ),
        ),
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
    // Flutter: weekday 1=Mon...7=Sun. We want Sun=0 offset.
    final firstWeekday = DateTime(year, month, 1).weekday % 7;
    final today = DateTime.now();

    final cells = <Widget>[];

    // Leading empty cells
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day;
      final hasEvents =
          CalendarService.instance.eventsForDate(date).isNotEmpty;

      cells.add(_DayCell(
        day: day,
        isToday: isToday,
        isSelected: isSelected,
        hasEvents: hasEvents,
        onTap: () => onDayTap(date),
      ));
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
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEvents;
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
                  fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.normal,
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
                color: isToday ? Colors.white70 : AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Selected day panel ────────────────────────────────────────────────────────

class _SelectedDayPanel extends StatelessWidget {
  const _SelectedDayPanel({required this.date, required this.onAddTap});

  final DateTime date;
  final VoidCallback onAddTap;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final events = CalendarService.instance.eventsForDate(date);

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
                label: const Text('Add Event',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (events.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No events on this day',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade400),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _DayEventTile(event: events[i]),
            ),
          ),
      ],
    );
  }
}

// ── Day event tile ────────────────────────────────────────────────────────────

class _DayEventTile extends StatelessWidget {
  const _DayEventTile({required this.event});
  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
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
              color: AppTheme.primary,
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
                if (event.recurrence != 'Does not repeat') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.repeat_rounded,
                          size: 11,
                          color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(event.recurrence,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditEventScreen(event: event),
              ),
            ),
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
        ],
      ),
    );
  }
}
