import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_bar.dart';
import '../core/theme.dart';
import '../services/lead_service.dart';

class NewLeadScreen extends StatefulWidget {
  const NewLeadScreen({super.key});

  @override
  State<NewLeadScreen> createState() => _NewLeadScreenState();
}

class _NewLeadScreenState extends State<NewLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _companyCtrl     = TextEditingController();
  final _contactCtrl     = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _gstinCtrl       = TextEditingController();
  final _stateNameCtrl   = TextEditingController();
  final _stateCodeCtrl   = TextEditingController();
  final _dealValueCtrl   = TextEditingController(text: '0.00');
  final _additionalNoteCtrl = TextEditingController();

  String  _status     = 'New';
  String  _leadSource = '— Unknown —';
  String? _lostReason;
  bool    _isLoading  = false;

  // ── Options ──────────────────────────────────────────────────────────────

  static const _statusOptions = [
    'New', 'Contacted', 'Follow Up', 'Closed', 'Lost',
  ];

  static const _leadSourceOptions = [
    '— Unknown —', 'Website', 'Referral', 'Social Media', 'Event',
    'Cold Call', 'Email Campaign', 'Partner', 'Call Capture (App)', 'Other',
  ];

  static const _lostReasonOptions = [
    'Price too high', 'Chose competitor', 'No budget', 'No response',
    'Project cancelled', 'Wrong timing', 'Other',
  ];

  bool get _isLost => _status == 'Lost';

  @override
  void dispose() {
    _companyCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    _stateNameCtrl.dispose();
    _stateCodeCtrl.dispose();
    _dealValueCtrl.dispose();
    _additionalNoteCtrl.dispose();
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────────────────────

  String _mapStatus(String display) {
    switch (display) {
      case 'Contacted':  return 'contacted';
      case 'Follow Up':  return 'follow_up';
      case 'Closed':     return 'closed';
      case 'Lost':       return 'lost';
      default:           return 'new';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await LeadService.instance.createLead(
      name: _companyCtrl.text.trim(),
      contactPerson: _contactCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      gstin: _gstinCtrl.text.trim(),
      stateName: _stateNameCtrl.text.trim(),
      stateCode: _stateCodeCtrl.text.trim(),
      status: _mapStatus(_status),
      source: _leadSource == '— Unknown —' ? '' : _leadSource,
      dealValue: double.tryParse(_dealValueCtrl.text) ?? 0.0,
      lostReason: _isLost ? _lostReason : null,
      lostReasonNote: _isLost ? _additionalNoteCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LeadResultDialog(isOffline: result.isOffline),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const LeadMantraAppBar(title: 'New Lead'),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _card(children: [
                  _textField(
                    ctrl: _companyCtrl,
                    label: 'Customer / Company Name',
                    hint: 'e.g. Acme Corp',
                    required: true,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    ctrl: _contactCtrl,
                    label: 'Contact Person',
                    hint: 'e.g. Pratik Shah',
                    helper: 'Individual to address on invoices and emails.',
                  ),
                  const SizedBox(height: 14),
                  _dropdown(
                    label: 'Status',
                    required: true,
                    value: _status,
                    items: _statusOptions,
                    onChanged: (v) => setState(() {
                      _status = v!;
                      _lostReason = null;
                    }),
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    ctrl: _emailCtrl,
                    label: 'Email',
                    hint: '',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    ctrl: _phoneCtrl,
                    label: 'Phone',
                    hint: '',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  _textField(
                    ctrl: _addressCtrl,
                    label: 'Address',
                    hint: 'Billing / shipping address...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  _textField(ctrl: _gstinCtrl, label: 'GSTIN', hint: 'e.g. 27AABCU9603R1ZX'),
                  const SizedBox(height: 14),
                  _textField(ctrl: _stateNameCtrl, label: 'State Name', hint: 'e.g. Maharashtra'),
                  const SizedBox(height: 14),
                  _textField(
                    ctrl: _stateCodeCtrl,
                    label: 'State Code',
                    hint: 'e.g. 27',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  _dropdown(
                    label: 'Lead Source',
                    value: _leadSource,
                    items: _leadSourceOptions,
                    onChanged: (v) => setState(() => _leadSource = v!),
                  ),
                  const SizedBox(height: 14),
                  _dealValueField(),

                  // Lost section — shown only when Status == Lost
                  if (_isLost) ...[
                    const SizedBox(height: 16),
                    _lostSection(),
                  ],
                ]),

                const SizedBox(height: 24),

                // Buttons
                _row([
                  _submitButton(),
                  _cancelButton(),
                ]),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Section builders ─────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) {
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
        children: children,
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }


  Widget _lostSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row([
            _dropdown(
              label: 'Lost Reason',
              labelColor: Colors.red.shade700,
              value: _lostReason,
              placeholder: '— Select a reason —',
              items: _lostReasonOptions,
              required: true,
              onChanged: (v) => setState(() => _lostReason = v),
              fillColor: Colors.white,
            ),
            _textField(
              ctrl: _additionalNoteCtrl,
              label: 'Additional Note',
              labelColor: Colors.red.shade700,
              hint: 'Optional detail...',
              fillColor: Colors.white,
            ),
          ]),
        ],
      ),
    );
  }

  // ── Field widgets ────────────────────────────────────────────────────────

  Widget _textField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    bool required = false,
    String? helper,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    Color? labelColor,
    Color? fillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required, color: labelColor),
        const SizedBox(height: 5),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDec(hint, fill: fillColor, maxLines: maxLines),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper,
            style: TextStyle(fontSize: 11, color: AppTheme.primary.withValues(alpha: 0.7)),
          ),
        ],
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
    String? value,
    String? placeholder,
    bool required = false,
    Color? labelColor,
    Color? fillColor,
  }) {
    final effective = value ?? placeholder ?? items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, required: required, color: labelColor),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: items.contains(effective) ? effective : null,
          isExpanded: true,
          itemHeight: null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          decoration: _inputDec(placeholder ?? '', fill: fillColor),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: SizedBox(
                      height: 36,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(e, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: required
              ? (v) => (v == null || v.isEmpty) ? 'Required' : null
              : null,
        ),
      ],
    );
  }

  Widget _dealValueField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Deal Value'),
        const SizedBox(height: 5),
        TextFormField(
          controller: _dealValueCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 13),
          decoration: _inputDec('0.00').copyWith(
            prefixIcon: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '\$',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Estimated deal value — used in pipeline reporting.',
          style: TextStyle(fontSize: 11, color: AppTheme.primary.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  // ── Button widgets ───────────────────────────────────────────────────────

  Widget _submitButton() {
    return SizedBox(
      height: 46,
      child: _isLoading
          ? Container(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                ),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submit,
              child: const Text(
                'Create Lead',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _cancelButton() {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[700],
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Cancel',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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
            ? [TextSpan(text: ' *', style: TextStyle(color: Colors.red.shade600))]
            : [],
      ),
    );
  }

  InputDecoration _inputDec(String hint, {Color? fill, int maxLines = 1}) {
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
}

// ── Result dialog ────────────────────────────────────────────────────────────

class _LeadResultDialog extends StatelessWidget {
  const _LeadResultDialog({required this.isOffline});
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                color: isOffline
                    ? const Color(0xFF78909C).withValues(alpha: 0.12)
                    : Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.check_circle_rounded,
                color: isOffline ? const Color(0xFF78909C) : Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isOffline ? 'Saved Offline' : 'Lead Created!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOffline
                  ? 'No internet connection. Your lead has been saved and will sync automatically when you are back online.'
                  : 'Your lead has been successfully created and uploaded to the server.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5),
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
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
