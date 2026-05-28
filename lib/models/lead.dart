class Lead {
  final String localId;
  final int? backendId;
  final String name;
  final String contactPerson;
  final String email;
  final String phone;
  final String address;
  final String gstin;
  final String stateName;
  final String stateCode;
  final String status;
  final String source;
  final double dealValue;
  final String? lostReason;
  final String? lostReasonNote;
  final bool isUploaded;
  final DateTime createdAt;

  const Lead({
    required this.localId,
    this.backendId,
    required this.name,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.address,
    required this.gstin,
    required this.stateName,
    required this.stateCode,
    required this.status,
    required this.source,
    required this.dealValue,
    this.lostReason,
    this.lostReasonNote,
    required this.isUploaded,
    required this.createdAt,
  });

  Lead copyWith({bool? isUploaded, int? backendId}) => Lead(
        localId: localId,
        backendId: backendId ?? this.backendId,
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
        isUploaded: isUploaded ?? this.isUploaded,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'backendId': backendId,
        'name': name,
        'contactPerson': contactPerson,
        'email': email,
        'phone': phone,
        'address': address,
        'gstin': gstin,
        'stateName': stateName,
        'stateCode': stateCode,
        'status': status,
        'source': source,
        'dealValue': dealValue,
        'lostReason': lostReason,
        'lostReasonNote': lostReasonNote,
        'isUploaded': isUploaded,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Lead.fromJson(Map<String, dynamic> j) => Lead(
        localId: j['localId'] as String,
        backendId: j['backendId'] as int?,
        name: j['name'] as String? ?? '',
        contactPerson: j['contactPerson'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        address: j['address'] as String? ?? '',
        gstin: j['gstin'] as String? ?? '',
        stateName: j['stateName'] as String? ?? '',
        stateCode: j['stateCode'] as String? ?? '',
        status: j['status'] as String? ?? 'new',
        source: j['source'] as String? ?? '',
        dealValue: (j['dealValue'] as num?)?.toDouble() ?? 0.0,
        lostReason: j['lostReason'] as String?,
        lostReasonNote: j['lostReasonNote'] as String?,
        isUploaded: j['isUploaded'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
