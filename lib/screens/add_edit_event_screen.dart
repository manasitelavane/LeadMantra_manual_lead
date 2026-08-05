import 'package:flutter/material.dart';

import '../core/app_bar.dart';
import '../core/theme.dart';
import '../models/calendar_event.dart';
import '../services/auth_service.dart';
import '../services/calendar_service.dart';

class AddEditEventScreen extends StatefulWidget {
  const AddEditEventScreen({super.key, this.event, this.initialDate});

  final CalendarEvent? event;
  final DateTime? initialDate;

  @override
  State<AddEditEventScreen> createState() => _AddEditEventScreenState();
}

class _AddEditEventScreenState extends State<AddEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();

  DateTime? _followUpDate;
  String _recurrence = 'Does not repeat';
  late String _assignTo;

  bool get _isEdit => widget.event != null;

  static const _recurrenceOptions = [
    'Does not repeat',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  String get _selfName {
    final u = AuthService.instance.user;
    if (u == null) return 'Yourself';
    return (u['name'] as String? ?? u['email'] as String? ?? 'Yourself').trim();
  }

  List<String> get _assignOptions => [
        '— Assign to yourself ($_selfName) —',
        '— Unassigned —',
      ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _noteCtrl.text = widget.event!.note;
      _followUpDate = widget.event!.followUpDate;
      _recurrence = widget.event!.recurrence;
      _assignTo = widget.event!.assignTo.isNotEmpty
          ? widget.event!.assignTo
          : '— Assign to yourself ($_selfName) —';
    } else {
      _followUpDate = widget.initialDate;
      _assignTo = '— Assign to yourself ($_selfName) —';
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _followUpDate = picked);
  }

  void _clearDate() => setState(() => _followUpDate = null);

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_isEdit) {
      CalendarService.instance.updateEvent(
        widget.event!.copyWith(
          note: _noteCtrl.text.trim(),
          followUpDate: _followUpDate,
          recurrence: _recurrence,
          assignTo: _assignTo,
        ),
      );
    } else {
      CalendarService.instance.addEvent(
        CalendarEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          note: _noteCtrl.text.trim(),
          followUpDate: _followUpDate,
          recurrence: _recurrence,
          assignTo: _assignTo,
          createdAt: DateTime.now(),
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: LeadMantraAppBar(title: _isEdit ? 'Edit Event' : 'Add Event'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(18),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Note ─────────────────────────────────────────────
                  _label('Note', required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noteCtrl,
                    minLines: 4,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDec('Enter your note here...', maxLines: 6),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Note is required' : null,
                  ),

                  const SizedBox(height: 18),

                  // ── Follow-up Date ────────────────────────────────────
                  _label('Follow-up Date', hint: '(optional)'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFE8EAF6), width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 16,
                              color: AppTheme.primary.withValues(alpha: 0.7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _followUpDate != null
                                  ? _formatDate(_followUpDate!)
                                  : 'dd-mm-yyyy',
                              style: TextStyle(
                                fontSize: 13,
                                color: _followUpDate != null
                                    ? Colors.black87
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                          if (_followUpDate != null)
                            GestureDetector(
                              onTap: _clearDate,
                              child: Icon(Icons.clear_rounded,
                                  size: 16, color: Colors.grey[400]),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Recurrence ────────────────────────────────────────
                  _label('Recurrence'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _recurrence,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20),
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black87),
                    decoration: _inputDec(''),
                    items: _recurrenceOptions
                        .map((o) => DropdownMenuItem(
                              value: o,
                              child: Text(o,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _recurrence = v!),
                  ),
                  if (_recurrence != 'Does not repeat') ...[
                    const SizedBox(height: 6),
                    Text(
                      'When marked done, the next occurrence will be created automatically.',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ── Assign to ─────────────────────────────────────────
                  _label('Assign to'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _assignTo,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20),
                    style:
                        const TextStyle(fontSize: 13, color: Colors.black87),
                    decoration: _inputDec(''),
                    items: _assignOptions
                        .map((o) => DropdownMenuItem(
                              value: o,
                              child: Text(o,
                                  style: const TextStyle(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _assignTo = v!),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Team members only see tasks assigned to them.',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),

                  const SizedBox(height: 24),

                  // ── Buttons ───────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _save,
                            child: Text(
                              _isEdit ? 'Update Note' : 'Save Note',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(
                                  color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text, {bool required = false, String? hint}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        if (required)
          Text(' *',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600)),
        if (hint != null) ...[
          const SizedBox(width: 4),
          Text(hint,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ],
    );
  }

  InputDecoration _inputDec(String hint, {int maxLines = 1}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8F9FF),
      contentPadding: EdgeInsets.symmetric(
          horizontal: 12, vertical: maxLines > 1 ? 12 : 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8EAF6), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      isDense: true,
    );
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }
}
