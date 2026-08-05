import 'package:flutter/foundation.dart';
import '../models/calendar_event.dart';

class CalendarService extends ChangeNotifier {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  final List<CalendarEvent> _events = [];

  List<CalendarEvent> get events => List.unmodifiable(_events);

  List<CalendarEvent> eventsForDate(DateTime date) => _events
      .where((e) =>
          e.followUpDate != null &&
          e.followUpDate!.year == date.year &&
          e.followUpDate!.month == date.month &&
          e.followUpDate!.day == date.day)
      .toList();

  void addEvent(CalendarEvent event) {
    _events.add(event);
    notifyListeners();
  }

  void updateEvent(CalendarEvent updated) {
    final i = _events.indexWhere((e) => e.id == updated.id);
    if (i != -1) {
      _events[i] = updated;
      notifyListeners();
    }
  }

  void deleteEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
