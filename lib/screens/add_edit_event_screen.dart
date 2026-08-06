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
  String _recurrence = 'none';
  String _status = 'pending';
  int? _assigneeId;
  bool _isLoading = false;

  static const _statusOptions = [
    ('pending',   'Pending',   Color(0xFF3B82F6)),
    ('done',      'Done',      Color(0xFF22C55E)),
    ('cancelled', 'Cancelled', Color(0xFF94A3B8)),
  ];

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _noteCtrl.text = widget.event!.note;
      _followUpDate = widget.event!.followUpDate;
      _recurrence = widget.event!.recurrence;
      _status = widget.event!.status;
      _assigneeId = widget.event!.assigneeId;
    } else {
      _followUpDate = widget.initialDate;
      _assigneeId = AuthService.instance.currentUserId;
    }
    CalendarService.instance.loadDropdowns();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final svc = CalendarService.instance;
    final NoteResult result;

    if (_isEdit) {
      final hadDate = widget.event!.followUpDate != null;
      result = await svc.updateNote(
        id: widget.event!.id,
        note: _noteCtrl.text.trim(),
        recurrence: _recurrence,
        status: _status,
        followUpDate: _followUpDate,
        clearFollowUpDate: hadDate && _followUpDate == null,
        assigneeId: svc.canAssignOthers ? _assigneeId : null,
        clearAssignee: svc.canAssignOthers && _assigneeId == null,
      );
    } else {
      result = await svc.createNote(
        note: _noteCtrl.text.trim(),
        followUpDate: _followUpDate,
        recurrence: _recurrence,
        status: _status,
        assigneeId: svc.canAssignOthers ? _assigneeId : null,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Something went wrong'),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    if (result.recurred && result.nextNoteDate != null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Recurring Note',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'This is a recurring note. Next occurrence has been created for ${_formatApiDate(result.nextNoteDate!)}.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: LeadMantraAppBar(title: _isEdit ? 'Edit Note' : 'Add Note'),
      body: ListenableBuilder(
        listenable: CalendarService.instance,
        builder: (context, _) {
          return SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCard(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final svc = CalendarService.instance;
    final recurrenceOptions = svc.recurrenceOptions;
    final assignees = svc.assignees;

    // Guard: if _recurrence is somehow not in the loaded list, reset to first
    final recurrenceInList = recurrenceOptions.any((o) => o.value == _recurrence);
    final effectiveRecurrence = recurrenceInList ? _recurrence : recurrenceOptions.first.value;

    // Guard: if _assigneeId is not in the loaded list, fall back to null
    final assigneeInList =
        _assigneeId == null || assignees.any((a) => a.id == _assigneeId);
    final effectiveAssigneeId = assigneeInList ? _assigneeId : null;

    return Container(
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
          // ── Note ─────────────────────────────────────────────────────────
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

          // ── Follow-up Date ────────────────────────────────────────────────
          _label('Follow-up Date', hint: '(optional)'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: const Color(0xFFE8EAF6), width: 1),
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

          // ── Recurrence ────────────────────────────────────────────────────
          _label('Recurrence'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: effectiveRecurrence,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            decoration: _inputDec(''),
            items: recurrenceOptions
                .map((o) => DropdownMenuItem(
                      value: o.value,
                      child: Text(o.label,
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _recurrence = v!),
          ),
          if (effectiveRecurrence != 'none') ...[
            const SizedBox(height: 6),
            Text(
              'When marked done, the next occurrence will be created automatically.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],

          const SizedBox(height: 18),

          // ── Status ────────────────────────────────────────────────────────
          _label('Status'),
          const SizedBox(height: 8),
          Row(
            children: _statusOptions.map((opt) {
              final isSelected = _status == opt.$1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _status = opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                        right: opt.$1 == 'cancelled' ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? opt.$3.withValues(alpha: 0.12)
                          : const Color(0xFFF8F9FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? opt.$3
                            : const Color(0xFFE8EAF6),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: opt.$3, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          opt.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? opt.$3
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // ── Assign to (admins only) ───────────────────────────────────────
          if (svc.canAssignOthers && assignees.isNotEmpty) ...[
            const SizedBox(height: 18),
            _label('Assign to'),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              initialValue: effectiveAssigneeId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              decoration: _inputDec(''),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('— Unassigned —',
                      style: TextStyle(fontSize: 13)),
                ),
                ...assignees.map((a) => DropdownMenuItem<int?>(
                      value: a.id,
                      child: Text(
                        a.isMe ? '${a.name} (You)' : a.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                    )),
              ],
              onChanged: (v) => setState(() => _assigneeId = v),
            ),
            const SizedBox(height: 6),
            Text(
              'Team members only see tasks assigned to them.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],

          const SizedBox(height: 24),

          // ── Buttons ───────────────────────────────────────────────────────
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
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
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
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed:
                        _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ],
          ),
        ],
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
              color: AppTheme.primary),
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
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8EAF6), width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppTheme.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      isDense: true,
    );
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd-$mm-${d.year}';
  }

  String _formatApiDate(String apiDate) {
    // apiDate is 'YYYY-MM-DD'
    final parts = apiDate.split('-');
    if (parts.length != 3) return apiDate;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    final label = (m >= 1 && m <= 12) ? months[m - 1] : parts[1];
    return '${parts[2]} $label ${parts[0]}';
  }
}
