import 'package:flutter/material.dart';

import '../core/app_bar.dart';
import '../core/theme.dart';
import '../models/lead.dart';
import '../services/lead_service.dart';
import 'edit_lead_screen.dart';

enum LeadType { total, uploaded, offline }

extension LeadTypeLabel on LeadType {
  String get label {
    switch (this) {
      case LeadType.total:    return 'Total Leads';
      case LeadType.uploaded: return 'Uploaded Leads';
      case LeadType.offline:  return 'Offline Leads';
    }
  }
}

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key, required this.type});

  final LeadType type;

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  bool _isSyncing = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Lead> get _leads {
    switch (widget.type) {
      case LeadType.total:    return LeadService.instance.allLeads;
      case LeadType.uploaded: return LeadService.instance.uploadedLeads;
      case LeadType.offline:  return LeadService.instance.offlineLeads;
    }
  }

  List<Lead> get _filteredLeads {
    if (_query.isEmpty) return _leads;
    final q = _query.toLowerCase();
    return _leads.where((l) =>
      l.name.toLowerCase().contains(q) ||
      l.contactPerson.toLowerCase().contains(q) ||
      l.phone.toLowerCase().contains(q) ||
      l.email.toLowerCase().contains(q),
    ).toList();
  }

  Future<void> _sync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    final result = await LeadService.instance.syncOfflineLeads();

    if (!mounted) return;
    setState(() => _isSyncing = false);

    if (!result.success) {
      _showSnackbar(result.error ?? 'Sync failed.', isError: true);
      return;
    }

    if (result.succeeded == 0) {
      _showSnackbar('Nothing to sync.', isError: false);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SyncResultDialog(
        succeeded: result.succeeded,
        failed: result.failed,
      ),
    );
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: LeadMantraAppBar(
        title: widget.type.label,
        actions: widget.type == LeadType.offline
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _isSyncing
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Sync offline leads',
                          icon: const Icon(
                            Icons.sync_rounded,
                            color: AppTheme.primary,
                          ),
                          onPressed: _sync,
                        ),
                ),
              ]
            : null,
      ),
      body: ListenableBuilder(
        listenable: LeadService.instance,
        builder: (context, _) {
          final leads = _filteredLeads;
          final hasLeads = _leads.isNotEmpty;

          return Column(
            children: [
              // ── Search bar ──────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search leads...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: AppTheme.primary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 16, color: AppTheme.primary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFFE8EAF6), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppTheme.primary, width: 1.5),
                    ),
                    isDense: true,
                  ),
                ),
              ),

              // ── List / empty state ──────────────────────────────────
              Expanded(
                child: leads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _query.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : widget.type == LeadType.offline
                                      ? Icons.wifi_off_rounded
                                      : Icons.people_alt_rounded,
                              size: 56,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _query.isNotEmpty
                                  ? 'No leads match your search'
                                  : 'No ${widget.type.label.toLowerCase()} yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.type == LeadType.offline &&
                                !hasLeads) ...[
                              const SizedBox(height: 6),
                              Text(
                                'All leads are synced!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: leads.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _LeadCard(lead: leads[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sync result dialog ───────────────────────────────────────────────────────

class _SyncResultDialog extends StatelessWidget {
  const _SyncResultDialog({required this.succeeded, required this.failed});
  final int succeeded;
  final int failed;

  @override
  Widget build(BuildContext context) {
    final hasFailures = failed > 0;
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
                color: hasFailures
                    ? Colors.orange.withValues(alpha: 0.12)
                    : Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFailures
                    ? Icons.sync_problem_rounded
                    : Icons.cloud_done_rounded,
                color: hasFailures ? Colors.orange : Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasFailures ? 'Sync Partial' : 'Sync Complete!',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            _StatRow(label: 'Uploaded', value: succeeded, color: Colors.green),
            if (hasFailures) ...[
              const SizedBox(height: 6),
              _StatRow(label: 'Failed', value: failed, color: Colors.red),
            ],
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

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Text(
          '$value',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}

// ── Lead card ────────────────────────────────────────────────────────────────

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});
  final Lead lead;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  lead.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _SyncBadge(isUploaded: lead.isUploaded),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditLeadScreen(lead: lead),
                  ),
                ),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 15,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (lead.contactPerson.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              lead.contactPerson,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (lead.phone.isNotEmpty)
                _InfoChip(
                    icon: Icons.phone_rounded,
                    label: lead.phone,
                    color: AppTheme.primary),
              if (lead.email.isNotEmpty)
                _InfoChip(
                    icon: Icons.email_rounded,
                    label: lead.email,
                    color: AppTheme.primary),
              _StatusChip(status: lead.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDate(lead.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.isUploaded});
  final bool isUploaded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isUploaded
            ? Colors.green.withValues(alpha: 0.10)
            : const Color(0xFF78909C).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUploaded ? Icons.cloud_done_rounded : Icons.wifi_off_rounded,
            size: 12,
            color: isUploaded ? Colors.green : const Color(0xFF78909C),
          ),
          const SizedBox(width: 4),
          Text(
            isUploaded ? 'Uploaded' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUploaded ? Colors.green : const Color(0xFF78909C),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'contacted' => ('Contacted', Colors.blue),
      'follow_up' => ('Follow Up', Colors.orange),
      'closed'    => ('Closed', Colors.green),
      'lost'      => ('Lost', Colors.red),
      _           => ('New', AppTheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
