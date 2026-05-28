import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/apiendpoint.dart';
import '../models/lead.dart';
import 'auth_service.dart';

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
      final token = AuthService.instance.token ?? '';
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

      final response = await http
          .post(
            Uri.parse(ApiEndpoint.createLead),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

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

    // Uploaded lead — call the API
    try {
      final token = AuthService.instance.token ?? '';
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

      final response = await http
          .put(
            Uri.parse(ApiEndpoint.updateLead(lead.backendId!)),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

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

      final token = AuthService.instance.token ?? '';
      final response = await http
          .post(
            Uri.parse(ApiEndpoint.syncLeads),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'operations': operations}),
          )
          .timeout(const Duration(seconds: 30));

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

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey, jsonEncode(_leads.map((l) => l.toJson()).toList()));
  }
}
