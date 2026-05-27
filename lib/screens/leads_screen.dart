import 'package:flutter/material.dart';

import '../core/app_bar.dart';

/// Lead type passed from the dashboard stat cards.
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

class LeadsScreen extends StatelessWidget {
  const LeadsScreen({super.key, required this.type});

  final LeadType type;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: LeadMantraAppBar(title: type.label),
      body: const SizedBox.shrink(),
    );
  }
}
