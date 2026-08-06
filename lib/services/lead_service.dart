import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/apiendpoint.dart';
import '../models/lead.dart';

class FetchLeadsResult {
  final bool success;
  final List<Lead> leads;
  final int total;
  final String? error;

  const FetchLeadsResult({
    required this.success,
    required this.leads,
    required this.total,
    this.error,
  });
}

class SyncResult {
  final bool success;
  final int succeeded;
  final int failed;
  final String? error;

  const SyncResult({
    required this.success,
    required this.succeeded,
    required this.failed,
    this.error,
  });
}

class UpdateLeadResult {
  final bool success;
  final Lead? lead;
  final String? error;

  const UpdateLeadResult({required this.success, this.lead, this.error});
}

class CreateLeadResult {
  final bool success;
  final bool isOffline;
  final Lead? lead;
  final String? error;

  const CreateLeadResult({
    required this.success,
    required this.isOffline,
    this.lead,
    this.error,
  });
}

class LeadService extends ChangeNotifier {
  LeadService._();
  static final LeadService instance = LeadService._();

  static const _prefKey = 'leads_list';

  List<Lead> _leads = [];
  int? _remoteTotal;

  int? get remoteTotal => _remoteTotal;

  List<Lead> get allLeads => List.unmodifiable(_leads);
  List<Lead> get uploadedLeads =>
      _leads.where((l) => l.isUploaded).toList();
  List<Lead> get offlineLeads =>
      _leads.where((l) => !l.isUploaded).toList();

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _leads = list
          .map((e) => Lead.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<CreateLeadResult> createLead({
    required String name,
    required String contactPerson,
    required String email,
    required String phone,
    required String address,
    required String gstin,
    required String stateName,
    required String stateCode,
    required String status,
    required String source,
    required double dealValue,
    String? lostReason,
    String? lostReasonNote,
  }) async {
    final localId = DateTime.now().millisecondsSinceEpoch.toString();
    final pendingLead = Lead(
      localId: localId,
      name: name,
      contactPerson: contactPerson,
      email: email,
      phone: phone,
      address: address,
      gstin: gstin,
      stateName: stateName,
      stateCode: stateCode,
      status: status,
      source: source,
      dealValue: dealValue,
      lostReason: lostReason,
      lostReasonNote: lostReasonNote,
      isUploaded: false,
      createdAt: DateTime.now(),
    );

    try {
      final body = <String, dynamic>{
        'name': name,
        'contact_person': contactPerson,
        'email': email,
        'phone': phone,
        'address': address,
        'gstin': gstin,
        'state_name': stateName,
        'state_code': stateCode,
        'status': status,
        'source': source,
        'deal_value': dealValue,
      };
      if (lostReason != null) body['lost_reason'] = lostReason;
      if (lostReasonNote != null && lostReasonNote.isNotEmpty) {
        body['lost_reason_note'] = lostReasonNote;
      }

      final response = await ApiClient.post(
        Uri.parse(ApiEndpoint.createLead),
        body: body,
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final backendId =
              (json['lead'] as Map<String, dynamic>?)?['id'] as int?;
          final uploaded =
              pendingLead.copyWith(isUploaded: true, backendId: backendId);
          _leads.add(uploaded);
          await _save();
          notifyListeners();
          return CreateLeadResult(
              success: true, isOffline: false, lead: uploaded);
        }
      }
      // Non-2xx or success:false → save offline
      _leads.add(pendingLead);
      await _save();
      notifyListeners();
      return CreateLeadResult(success: true, isOffline: true, lead: pendingLead);
    } on SocketException {
      _leads.add(pendingLead);
      await _save();
      notifyListeners();
      return CreateLeadResult(success: true, isOffline: true, lead: pendingLead);
    } catch (_) {
      _leads.add(pendingLead);
      await _save();
      notifyListeners();
      return CreateLeadResult(success: true, isOffline: true, lead: pendingLead);
    }
  }

  Future<UpdateLeadResult> updateLead({
    required String localId,
    required String status,
    required String phone,
    required double dealValue,
    String? lostReason,
    String? lostReasonNote,
  }) async {
    final idx = _leads.indexWhere((l) => l.localId == localId);
    if (idx == -1) {
      return const UpdateLeadResult(success: false, error: 'Lead not found.');
    }
    final lead = _leads[idx];

    Lead makeUpdated() => Lead(
          localId: lead.localId,
          backendId: lead.backendId,
          name: lead.name,
          contactPerson: lead.contactPerson,
          email: lead.email,
          phone: phone,
          address: lead.address,
          gstin: lead.gstin,
          stateName: lead.stateName,
          stateCode: lead.stateCode,
          status: status,
          source: lead.source,
          dealValue: dealValue,
          lostReason: status == 'lost' ? lostReason : null,
          lostReasonNote: status == 'lost' ? lostReasonNote : null,
          isUploaded: lead.isUploaded,
          createdAt: lead.createdAt,
        );

    // Offline lead — update locally only, sync will pick up new values later
    if (!lead.isUploaded || lead.backendId == null) {
      final updated = makeUpdated();
      _leads[idx] = updated;
      await _save();
      notifyListeners();
      return UpdateLeadResult(success: true, lead: updated);
    }

    // Lead not in local storage — remote-only lead (localId == backendId string)
    if (idx == -1) {
      final remoteId = int.tryParse(localId);
      if (remoteId == null) {
        return const UpdateLeadResult(success: false, error: 'Lead not found.');
      }
      return _callUpdateApi(
        backendId: remoteId,
        status: status,
        phone: phone,
        dealValue: dealValue,
        lostReason: lostReason,
        lostReasonNote: lostReasonNote,
      );
    }

    // Uploaded lead — call the API
    try {
      final body = <String, dynamic>{
        'status': status,
        'phone': phone,
        'deal_value': dealValue,
      };
      if (status == 'lost') {
        if (lostReason != null) body['lost_reason'] = lostReason;
        if (lostReasonNote != null && lostReasonNote.isNotEmpty) {
          body['lost_reason_note'] = lostReasonNote;
        }
      }

      final response = await ApiClient.post(
        Uri.parse(ApiEndpoint.updateLead(lead.backendId!)),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final updated = makeUpdated();
          _leads[idx] = updated;
          await _save();
          notifyListeners();
          return UpdateLeadResult(success: true, lead: updated);
        }
      }
      return const UpdateLeadResult(
          success: false, error: 'Server error. Please try again.');
    } on SocketException {
      return const UpdateLeadResult(
          success: false,
          error: 'No internet connection. Please try again when online.');
    } catch (_) {
      return const UpdateLeadResult(
          success: false, error: 'Something went wrong. Please try again.');
    }
  }

  Future<SyncResult> syncOfflineLeads() async {
    final offline = offlineLeads;
    if (offline.isEmpty) {
      return const SyncResult(success: true, succeeded: 0, failed: 0);
    }

    try {
      // Quick connectivity check before committing to a full request
      await InternetAddress.lookup('leadmantracrm.com')
          .timeout(const Duration(seconds: 5));
    } on SocketException {
      return const SyncResult(
        success: false,
        succeeded: 0,
        failed: 0,
        error: 'No internet connection. Please try again when online.',
      );
    } catch (_) {
      return const SyncResult(
        success: false,
        succeeded: 0,
        failed: 0,
        error: 'No internet connection. Please try again when online.',
      );
    }

    try {
      final operations = offline.map((lead) {
        final op = <String, dynamic>{
          'name': lead.name,
          'contact_person': lead.contactPerson,
          'email': lead.email,
          'phone': lead.phone,
          'address': lead.address,
          'gstin': lead.gstin,
          'state_name': lead.stateName,
          'state_code': lead.stateCode,
          'status': lead.status,
          'source': lead.source,
          'deal_value': lead.dealValue,
        };
        if (lead.backendId != null) op['id'] = lead.backendId;
        if (lead.lostReason != null) op['lost_reason'] = lead.lostReason;
        if (lead.lostReasonNote != null && lead.lostReasonNote!.isNotEmpty) {
          op['lost_reason_note'] = lead.lostReasonNote;
        }
        return op;
      }).toList();

      final response = await ApiClient.post(
        Uri.parse(ApiEndpoint.syncLeads),
        body: {'operations': operations},
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final results = json['results'] as List<dynamic>;

          // Match results to offline leads by position order
          for (int i = 0; i < results.length && i < offline.length; i++) {
            final r = results[i] as Map<String, dynamic>;
            if (r['success'] == true) {
              final localLead = offline[i];
              final leadData = r['lead'] as Map<String, dynamic>?;
              final backendId = leadData?['id'] as int? ??
                  r['lead_id'] as int?;
              final idx =
                  _leads.indexWhere((l) => l.localId == localLead.localId);
              if (idx != -1) {
                _leads[idx] =
                    _leads[idx].copyWith(isUploaded: true, backendId: backendId);
              }
            } else {
              final devError = r['dev_error'] as String?;
              final error    = r['error']     as String?;
              final action   = r['action']    as String? ?? 'unknown';
              final localId  = r['local_id'];
              print('── SYNC FAILED [$action] local_id=$localId');
              print('   error    : $error');
              if (devError != null) print('   dev_error: $devError');
            }
          }

          await _save();
          notifyListeners();
          return SyncResult(
            success: true,
            succeeded: json['succeeded'] as int? ?? 0,
            failed: json['failed'] as int? ?? 0,
          );
        }
      }

      return const SyncResult(
        success: false,
        succeeded: 0,
        failed: 0,
        error: 'Server error. Please try again.',
      );
    } on SocketException {
      return const SyncResult(
        success: false,
        succeeded: 0,
        failed: 0,
        error: 'No internet connection. Please try again when online.',
      );
    } catch (_) {
      return const SyncResult(
        success: false,
        succeeded: 0,
        failed: 0,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<UpdateLeadResult> _callUpdateApi({
    required int backendId,
    required String status,
    required String phone,
    required double dealValue,
    String? lostReason,
    String? lostReasonNote,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': status,
        'phone': phone,
        'deal_value': dealValue,
      };
      if (status == 'lost') {
        if (lostReason != null) body['lost_reason'] = lostReason;
        if (lostReasonNote != null && lostReasonNote.isNotEmpty) {
          body['lost_reason_note'] = lostReasonNote;
        }
      }
      final response = await ApiClient.post(
        Uri.parse(ApiEndpoint.updateLead(backendId)),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          return const UpdateLeadResult(success: true);
        }
      }
      return const UpdateLeadResult(
          success: false, error: 'Server error. Please try again.');
    } on SocketException {
      return const UpdateLeadResult(
          success: false,
          error: 'No internet connection. Please try again when online.');
    } catch (_) {
      return const UpdateLeadResult(
          success: false, error: 'Something went wrong. Please try again.');
    }
  }

  Future<FetchLeadsResult> fetchLeads({
    String search = '',
    String status = '',
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiEndpoint.leadsList),
        body: {
          'search': search,
          'status': status,
          'source': '',
          'per_page': perPage,
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final data = json['data'] as List<dynamic>;
          final meta = json['meta'] as Map<String, dynamic>;
          final total = meta['total'] as int? ?? 0;

          final leads = data.map((e) {
            final m = e as Map<String, dynamic>;
            final id = m['id'] as int;
            return Lead(
              localId: id.toString(),
              backendId: id,
              name: m['name'] as String? ?? '',
              contactPerson: m['contact_person'] as String? ?? '',
              email: m['email'] as String? ?? '',
              phone: m['phone'] as String? ?? '',
              address: m['address'] as String? ?? '',
              gstin: m['gstin'] as String? ?? '',
              stateName: m['state_name'] as String? ?? '',
              stateCode: m['state_code'] as String? ?? '',
              status: m['status'] as String? ?? 'new',
              source: m['source'] as String? ?? '',
              dealValue: (m['deal_value'] as num?)?.toDouble() ?? 0.0,
              lostReason: m['lost_reason'] as String?,
              lostReasonNote: m['lost_reason_note'] as String?,
              isUploaded: true,
              createdAt: DateTime.tryParse(
                      m['created_at'] as String? ?? '') ??
                  DateTime.now(),
            );
          }).toList();

          if (page == 1) {
            _remoteTotal = total;
            notifyListeners();
          }

          return FetchLeadsResult(
              success: true, leads: leads, total: total);
        }
      }
      return const FetchLeadsResult(
          success: false,
          leads: [],
          total: 0,
          error: 'Failed to load leads. Please try again.');
    } on SocketException {
      return const FetchLeadsResult(
          success: false,
          leads: [],
          total: 0,
          error: 'No internet connection.');
    } catch (_) {
      return const FetchLeadsResult(
          success: false,
          leads: [],
          total: 0,
          error: 'Something went wrong. Please try again.');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey, jsonEncode(_leads.map((l) => l.toJson()).toList()));
  }
}
