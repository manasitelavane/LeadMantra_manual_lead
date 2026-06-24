import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_bar.dart';
import '../core/theme.dart';
import '../models/lead.dart';
import '../services/lead_service.dart';

class EditLeadScreen extends StatefulWidget {
  const EditLeadScreen({super.key, required this.lead});
  final Lead lead;

  @override
  State<EditLeadScreen> createState() => _EditLeadScreenState();
}

class _EditLeadScreenState extends State<EditLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dealValueCtrl;
  late final TextEditingController _lostNoteCtrl;

  late String _status;
  String? _lostReasonCode;
  bool _isLoading = false;

  // (display label, api value)
  static const _statusOptions = [
    ('New', 'new'),
    ('Contacted', 'contacted'),
    ('Follow Up', 'follow_up'),
    ('Closed', 'closed'),
    ('Lost', 'lost'),
  ];

  static const _lostReasonOptions = [
    ('Price too high', 'price'),
    ('Chose competitor', 'competitor'),
    ('No budget', 'no_budget'),
    ('No response', 'no_response'),
    ('Project cancelled', 'cancelled'),
    ('Wrong timing', 'timing'),
    ('Other', 'other'),
  ];

  bool get _isLost => _status == 'lost';

  @override
  void initState() {
    super.initState();
    _status = widget.lead.status;
    _phoneCtrl = TextEditingController(text: widget.lead.phone);
    _dealValueCtrl =
        TextEditingController(text: widget.lead.dealValue.toStringAsFixed(2));
    _lostNoteCtrl =
        TextEditingController(text: widget.lead.lostReasonNote ?? '');

    if (widget.lead.lostReason != null) {
      final known =
          _lostReasonOptions.any((o) => o.$2 == widget.lead.lostReason);
      _lostReasonCode =
          known ? widget.lead.lostReason : _lostReasonOptions.first.$2;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _dealValueCtrl.dispose();
    _lostNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await LeadService.instance.updateLead(
      localId: widget.lead.localId,
      status: _status,
      phone: _phoneCtrl.text.trim(),
      dealValue: double.tryParse(_dealValueCtrl.text) ?? 0.0,
      lostReason: _isLost ? _lostReasonCode : null,
      lostReasonNote: _isLost ? _lostNoteCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _UpdateSuccessDialog(),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Update failed.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const LeadMantraAppBar(title: 'Edit Lead'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoCard(),
                const SizedBox(height: 16),
                _editCard(),
                const SizedBox(height: 24),
                _buttonsRow(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Read-only lead header ─────────────────────────────────────────────────

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 13,
                  color: AppTheme.primary.withValues(alpha: 0.6)),
              const SizedBox(width: 5),
              Text(
                'Read-only fields',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.lead.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          if (widget.lead.contactPerson.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(widget.lead.contactPerson,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
          if (widget.lead.email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(widget.lead.email,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }

  // ── Editable fields card ──────────────────────────────────────────────────

  Widget _editCard() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status
          _label('Status', required: true),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            initialValue: _status,
            isExpanded: true,
            itemHeight: null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            decoration: _inputDec(''),
            items: _statusOptions
                .map((o) => DropdownMenuItem(
                      value: o.$2,
                      child: SizedBox(
                        height: 36,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(o.$1,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _status = v!;
              if (_status != 'lost') _lostReasonCode = null;
            }),
          ),

          const SizedBox(height: 14),

          // Phone
          _label('Phone'),
          const SizedBox(height: 5),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 13),
            decoration: _inputDec('e.g. 9999999999'),
            validator: (v) {
              final digits = v?.trim() ?? '';
              if (digits.isEmpty) return null;
              if (digits.length != 10) return 'Phone must be exactly 10 digits';
              return null;
            },
          ),

          const SizedBox(height: 14),

          // Deal value
          _label('Deal Value'),
          const SizedBox(height: 5),
          TextFormField(
            controller: _dealValueCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13),
            validator: (v) {
              final val = double.tryParse(v ?? '');
              if (val != null && val > 10000000000) {
                return 'Deal value cannot exceed ₹1000 Cr';
              }
              return null;
            },
            decoration: _inputDec('0.00').copyWith(
              prefixIcon: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '₹',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary),
                ),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),

          // Lost reason section
          if (_isLost) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Lost Reason',
                      required: true, color: Colors.red.shade700),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    initialValue: _lostReasonCode,
                    isExpanded: true,
                    itemHeight: null,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20),
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87),
                    decoration:
                        _inputDec('— Select a reason —', fill: Colors.white),
                    items: _lostReasonOptions
                        .map((o) => DropdownMenuItem(
                              value: o.$2,
                              child: SizedBox(
                                height: 36,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(o.$1,
                                      style: const TextStyle(fontSize: 13)),
                                ),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _lostReasonCode = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _label('Additional Note', color: Colors.red.shade700),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _lostNoteCtrl,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDec('Optional detail...',
                        fill: Colors.white, maxLines: 3),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Buttons ───────────────────────────────────────────────────────────────

  Widget _buttonsRow() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 46,
            child: _isLoading
                ? Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      ),
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: const Text(
                      'Update Lead',
                      style: TextStyle(
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
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text, {bool required = false, Color? color}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? AppTheme.primary,
        ),
        children: required
            ? [
                TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red.shade600))
              ]
            : [],
      ),
    );
  }

  InputDecoration _inputDec(String hint,
      {Color? fill, int maxLines = 1}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      filled: true,
      fillColor: fill ?? const Color(0xFFF8F9FF),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: maxLines > 1 ? 12 : 10,
      ),
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
        borderSide:
            const BorderSide(color: AppTheme.primary, width: 1.5),
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
}

// ── Success dialog ────────────────────────────────────────────────────────────

class _UpdateSuccessDialog extends StatelessWidget {
  const _UpdateSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lead Updated!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The lead has been successfully updated.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
