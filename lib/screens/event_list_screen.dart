import 'package:flutter/material.dart';

import '../core/app_bar.dart';
import '../core/theme.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import 'add_edit_event_screen.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _confirmDelete(BuildContext context, CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to delete this event?',
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
    if (confirmed == true) {
      CalendarService.instance.deleteEvent(event.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const LeadMantraAppBar(title: 'All Events'),
      body: ListenableBuilder(
        listenable: CalendarService.instance,
        builder: (context, _) {
          final events = CalendarService.instance.events;

          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_note_rounded,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No events scheduled yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort by follow-up date (events with dates first, then by date)
          final sorted = [...events]..sort((a, b) {
              if (a.followUpDate == null && b.followUpDate == null) return 0;
              if (a.followUpDate == null) return 1;
              if (b.followUpDate == null) return -1;
              return a.followUpDate!.compareTo(b.followUpDate!);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _EventCard(
              event: sorted[i],
              formatDate: _formatDate,
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditEventScreen(event: sorted[i]),
                ),
              ),
              onDelete: () => _confirmDelete(context, sorted[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Event card ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete,
  });

  final CalendarEvent event;
  final String Function(DateTime) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note + action buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.note,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Edit
              _ActionBtn(
                icon: Icons.edit_rounded,
                color: AppTheme.primary,
                onTap: onEdit,
              ),
              const SizedBox(width: 6),
              // Delete
              _ActionBtn(
                icon: Icons.delete_outline_rounded,
                color: Colors.red.shade400,
                onTap: onDelete,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Meta row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              if (event.followUpDate != null)
                _MetaChip(
                  icon: Icons.calendar_today_rounded,
                  label: formatDate(event.followUpDate!),
                  color: AppTheme.primary,
                ),
              if (event.recurrence != 'Does not repeat')
                _MetaChip(
                  icon: Icons.repeat_rounded,
                  label: event.recurrence,
                  color: Colors.orange,
                ),
              if (event.assignTo.isNotEmpty &&
                  !event.assignTo.contains('Unassigned'))
                _MetaChip(
                  icon: Icons.person_outline_rounded,
                  label: event.assignTo
                      .replaceAll('— ', '')
                      .replaceAll(' —', ''),
                  color: Colors.teal,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
