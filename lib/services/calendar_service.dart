import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/apiendpoint.dart';
import '../models/calendar_event.dart';

// ── Value objects ─────────────────────────────────────────────────────────────

class RecurrenceOption {
  final String value;
  final String label;
  const RecurrenceOption(this.value, this.label);
}

class CalendarAssignee {
  final int id;
  final String name;
  final bool isMe;
  const CalendarAssignee({
    required this.id,
    required this.name,
    this.isMe = false,
  });
}

class NoteResult {
  final bool success;
  final String? error;
  final bool recurred;
  final String? nextNoteDate;

  const NoteResult({
    required this.success,
    this.error,
    this.recurred = false,
    this.nextNoteDate,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class CalendarService extends ChangeNotifier {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  // ── Grid state ────────────────────────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _gridDays = {};
  String? _gridMonth;
  bool isLoadingGrid = false;
  String? gridError;

  // ── Day notes cache (by date key) ─────────────────────────────────────────
  final Map<String, List<CalendarEvent>> _notesCache = {};
  bool isLoadingNotes = false;
  String? notesError;

  // ── All notes (list screen) ───────────────────────────────────────────────
  List<CalendarEvent> allNotes = const [];
  bool isLoadingAll = false;
  String? allNotesError;

  // ── Dropdowns ─────────────────────────────────────────────────────────────
  List<RecurrenceOption> recurrenceOptions = const [
    RecurrenceOption('none',      'Does not repeat'),
    RecurrenceOption('daily',     'Daily'),
    RecurrenceOption('weekly',    'Weekly'),
    RecurrenceOption('monthly',   'Monthly'),
    RecurrenceOption('quarterly', 'Quarterly'),
    RecurrenceOption('yearly',    'Yearly'),
  ];
  List<CalendarAssignee> assignees = const [];
  bool canAssignOthers = false;
  bool dropdownsLoaded = false;
  bool isLoadingDropdowns = false;

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  Map<String, dynamic>? getDayData(DateTime date) => _gridDays[_dateKey(date)];

  List<CalendarEvent> getNotesForDate(DateTime date) =>
      _notesCache[_dateKey(date)] ?? const [];

  String recurrenceLabel(String value) => recurrenceOptions
      .firstWhere(
        (o) => o.value == value,
        orElse: () => RecurrenceOption(value, value),
      )
      .label;

  void _invalidateCaches() {
    _notesCache.clear();
    _gridDays.clear();
    _gridMonth = null;
  }

  // ── Load dropdowns ────────────────────────────────────────────────────────

  Future<void> loadDropdowns() async {
    if (dropdownsLoaded || isLoadingDropdowns) return;
    isLoadingDropdowns = true;
    notifyListeners();

    try {
      final uri = Uri.parse(ApiEndpoint.dropdowns).replace(
        queryParameters: {'keys': 'recurrence,assignees,defaults'},
      );
      final response = await ApiClient.get(uri);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;

          final recList = data['recurrence'] as List?;
          if (recList != null && recList.isNotEmpty) {
            recurrenceOptions = recList.map((r) {
              final m = r as Map<String, dynamic>;
              return RecurrenceOption(
                m['value'] as String,
                m['label'] as String,
              );
            }).toList();
          }

          final assList = data['assignees'] as List?;
          if (assList != null) {
            assignees = assList.map((a) {
              final m = a as Map<String, dynamic>;
              return CalendarAssignee(
                id: m['id'] as int,
                name: m['name'] as String,
                isMe: m['is_me'] as bool? ?? false,
              );
            }).toList();
          }

          final defaults = data['defaults'] as Map<String, dynamic>?;
          canAssignOthers = defaults?['can_assign_others'] as bool? ?? false;
          dropdownsLoaded = true;
        }
      }
    } catch (_) {}

    isLoadingDropdowns = false;
    notifyListeners();
  }

  // ── Load month grid ───────────────────────────────────────────────────────

  Future<void> loadMonthGrid(DateTime month) async {
    final monthStr = _monthKey(month);
    if (_gridMonth == monthStr) return;

    isLoadingGrid = true;
    gridError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(ApiEndpoint.calendarGrid).replace(
        queryParameters: {'month': monthStr, 'timezone': 'Asia/Kolkata'},
      );
      final response = await ApiClient.get(uri);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          _gridDays.clear();
          for (final day in body['days'] as List) {
            final d = day as Map<String, dynamic>;
            _gridDays[d['date'] as String] = d;
          }
          _gridMonth = monthStr;
        } else {
          gridError = body['message'] as String? ?? 'Failed to load calendar';
        }
      }
    } on SocketException {
      gridError = 'No internet connection';
    } catch (_) {
      gridError = 'Failed to load calendar';
    }

    isLoadingGrid = false;
    notifyListeners();
  }

  // ── Load notes for a date ─────────────────────────────────────────────────

  Future<void> loadNotesForDate(DateTime date) async {
    final key = _dateKey(date);
    isLoadingNotes = true;
    notesError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(ApiEndpoint.calendarNotes).replace(
        queryParameters: {'date': key, 'timezone': 'Asia/Kolkata'},
      );
      final response = await ApiClient.get(uri);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          _notesCache[key] = (body['data'] as List)
              .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          notesError = body['message'] as String? ?? 'Failed to load notes';
        }
      }
    } on SocketException {
      notesError = 'No internet connection';
    } catch (_) {
      notesError = 'Failed to load notes';
    }

    isLoadingNotes = false;
    notifyListeners();
  }

  // ── Load all notes (list screen) ──────────────────────────────────────────

  Future<void> loadAllNotes() async {
    isLoadingAll = true;
    allNotesError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(ApiEndpoint.calendarNotes).replace(
        queryParameters: {'per_page': '100', 'page': '1'},
      );
      final response = await ApiClient.get(uri);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          allNotes = (body['data'] as List)
              .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          allNotesError =
              body['message'] as String? ?? 'Failed to load notes';
        }
      }
    } on SocketException {
      allNotesError = 'No internet connection';
    } catch (_) {
      allNotesError = 'Failed to load notes';
    }

    isLoadingAll = false;
    notifyListeners();
  }

  // ── Create note ───────────────────────────────────────────────────────────

  Future<NoteResult> createNote({
    required String note,
    DateTime? followUpDate,
    String recurrence = 'none',
    String status = 'pending',
    int? assigneeId,
  }) async {
    try {
      final body = <String, dynamic>{
        'note': note,
        'recur_interval': recurrence,
        'status': status,
      };
      if (followUpDate != null) body['follow_up_date'] = _dateKey(followUpDate);
      if (assigneeId != null) body['assign_to_user_id'] = assigneeId;

      final response = await ApiClient.post(
        Uri.parse(ApiEndpoint.calendarNotes),
        body: body,
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          json['success'] == true) {
        _invalidateCaches();
        notifyListeners();
        return const NoteResult(success: true);
      }
      return NoteResult(
        success: false,
        error: json['message'] as String? ?? 'Failed to create note',
      );
    } on SocketException {
      return const NoteResult(success: false, error: 'No internet connection');
    } catch (_) {
      return const NoteResult(
          success: false, error: 'Something went wrong. Please try again.');
    }
  }

  // ── Update note ───────────────────────────────────────────────────────────

  Future<NoteResult> updateNote({
    required String id,
    required String note,
    required String recurrence,
    required String status,
    DateTime? followUpDate,
    bool clearFollowUpDate = false,
    int? assigneeId,
    bool clearAssignee = false,
  }) async {
    final noteId = int.tryParse(id);
    if (noteId == null) {
      return const NoteResult(success: false, error: 'Invalid note ID');
    }

    try {
      final body = <String, dynamic>{
        'note': note,
        'recur_interval': recurrence,
        'status': status,
      };

      if (clearFollowUpDate) {
        body['follow_up_date'] = null;
      } else if (followUpDate != null) {
        body['follow_up_date'] = _dateKey(followUpDate);
      }

      if (clearAssignee) {
        body['assign_to_user_id'] = null;
      } else if (assigneeId != null) {
        body['assign_to_user_id'] = assigneeId;
      }

      final response = await ApiClient.post(
        Uri.parse(ApiEndpoint.calendarNote(noteId)),
        body: body,
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && json['success'] == true) {
        _invalidateCaches();
        notifyListeners();
        final recurred = json['recurred'] as bool? ?? false;
        final nextNote = json['next_note'] as Map<String, dynamic>?;
        return NoteResult(
          success: true,
          recurred: recurred,
          nextNoteDate: nextNote?['date'] as String?,
        );
      }
      return NoteResult(
        success: false,
        error: json['message'] as String? ?? 'Failed to update note',
      );
    } on SocketException {
      return const NoteResult(success: false, error: 'No internet connection');
    } catch (_) {
      return const NoteResult(
          success: false, error: 'Something went wrong. Please try again.');
    }
  }

  // ── Delete note ───────────────────────────────────────────────────────────

  Future<NoteResult> deleteNote(String id) async {
    final noteId = int.tryParse(id);
    if (noteId == null) {
      return const NoteResult(success: false, error: 'Invalid note ID');
    }

    try {
      final response = await ApiClient.post(
        Uri.parse(ApiEndpoint.calendarNoteDelete(noteId)),
        body: {},
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && json['success'] == true) {
        _invalidateCaches();
        notifyListeners();
        return const NoteResult(success: true);
      }
      return NoteResult(
        success: false,
        error: json['message'] as String? ?? 'Failed to delete note',
      );
    } on SocketException {
      return const NoteResult(success: false, error: 'No internet connection');
    } catch (_) {
      return const NoteResult(
          success: false, error: 'Something went wrong. Please try again.');
    }
  }
}
