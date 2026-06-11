import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_bar.dart';
import '../core/theme.dart';
import '../models/lead.dart';
import '../services/lead_service.dart';

class TotalLeadsScreen extends StatefulWidget {
  const TotalLeadsScreen({super.key});

  @override
  State<TotalLeadsScreen> createState() => _TotalLeadsScreenState();
}

class _TotalLeadsScreenState extends State<TotalLeadsScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  List<Lead> _leads = [];
  int _total = 0;
  int _page = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String _search = '';
  String _statusFilter = '';
  Timer? _debounce;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch(refresh: true);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _page = 1;
        _leads = [];
        _hasMore = true;
      }
    });

    final result = await LeadService.instance.fetchLeads(
      search: _search,
      status: _statusFilter,
      page: 1,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _leads = result.leads;
        _total = result.total;
        _page = 1;
        _hasMore = _leads.length < _total;
      } else {
        _error = result.error;
      }
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await LeadService.instance.fetchLeads(
      search: _search,
      status: _statusFilter,
      page: _page + 1,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (result.success) {
        _leads.addAll(result.leads);
        _page += 1;
        _hasMore = _leads.length < _total;
      }
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search = value.trim();
      _fetch(refresh: true);
    });
  }

  void _onStatusChanged(String? value) {
    _statusFilter = value ?? '';
    _fetch(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: LeadMantraAppBar(
        title: _total > 0 ? 'Total Leads ($_total)' : 'Total Leads',
      ),
      body: Column(
        children: [
          // ── Search + filter bar ────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search leads...',
                      hintStyle: TextStyle(
                          fontSize: 13, color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: AppTheme.primary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  size: 16, color: AppTheme.primary),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearchChanged('');
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
                const SizedBox(width: 8),
                _StatusFilterDropdown(
                  value: _statusFilter,
                  onChanged: _onStatusChanged,
                ),
              ],
            ),
          ),

          // ── List / states ──────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(
                        error: _error!,
                        onRetry: () => _fetch(refresh: true),
                      )
                    : _leads.isEmpty
                        ? _EmptyView(hasFilter: _search.isNotEmpty || _statusFilter.isNotEmpty)
                        : RefreshIndicator(
                            onRefresh: () => _fetch(refresh: true),
                            child: ListView.separated(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  _leads.length + (_isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                if (i == _leads.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5),
                                    ),
                                  );
                                }
                                return _RemoteLeadCard(lead: _leads[i]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Status filter dropdown ────────────────────────────────────────────────────

class _StatusFilterDropdown extends StatelessWidget {
  const _StatusFilterDropdown(
      {required this.value, required this.onChanged});
  final String value;
  final void Function(String?) onChanged;

  static const _options = [
    ('All', ''),
    ('New', 'new'),
    ('Contacted', 'contacted'),
    ('Follow Up', 'follow_up'),
    ('Closed', 'closed'),
    ('Lost', 'lost'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EAF6), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: AppTheme.primary),
          items: _options
              .map((o) => DropdownMenuItem(
                    value: o.$2,
                    child: Text(o.$1,
                        style: const TextStyle(fontSize: 12)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Empty view ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilter ? Icons.search_off_rounded : Icons.people_alt_rounded,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            hasFilter ? 'No leads match your filter' : 'No leads yet',
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
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry',
                  style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lead card ─────────────────────────────────────────────────────────────────

class _RemoteLeadCard extends StatelessWidget {
  const _RemoteLeadCard({required this.lead});
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
          // Name + source
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
              if (lead.source.isNotEmpty) ...[
                const SizedBox(width: 6),
                _SourceBadge(source: lead.source),
              ],
            ],
          ),

          if (lead.contactPerson.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              lead.contactPerson,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600),
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
                    label: lead.phone),
              if (lead.email.isNotEmpty)
                _InfoChip(
                    icon: Icons.email_rounded,
                    label: lead.email),
              _StatusChip(status: lead.status),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            _formatDate(lead.createdAt),
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade400),
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

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final String source;

  String get _label => source
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12,
            color: AppTheme.primary.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade700)),
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
            color: color),
      ),
    );
  }
}
