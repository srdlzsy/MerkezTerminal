import 'package:furpa_merkez_terminal/core/network/api_client.dart';

abstract class DespatchDriversRepository {
  Future<List<DespatchDriverLookupItem>> searchDrivers({
    required String accessToken,
    String search = '',
    bool includeInactive = false,
    int take = 20,
  });
}

class ApiDespatchDriversRepository implements DespatchDriversRepository {
  const ApiDespatchDriversRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<DespatchDriverLookupItem>> searchDrivers({
    required String accessToken,
    String search = '',
    bool includeInactive = false,
    int take = 20,
  }) async {
    final normalizedSearch = search.trim();
    final response = await _apiClient.getJsonList(
      '/api/ayar-islemleri/soforler',
      accessToken: accessToken,
      queryParameters: <String, String>{
        'includeInactive': includeInactive.toString(),
        'take': take.clamp(1, 500).toString(),
        if (normalizedSearch.isNotEmpty) 'search': normalizedSearch,
      },
    );

    return response
        .map(
          (item) => DespatchDriverLookupItem.fromJson(
            item as JsonMap? ?? <String, dynamic>{},
          ),
        )
        .toList(growable: false);
  }
}

class DespatchDriverLookupItem {
  const DespatchDriverLookupItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.plateNumber,
    required this.tckn,
    required this.maskedTckn,
    required this.isActive,
    this.notes,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String plateNumber;
  final String tckn;
  final String maskedTckn;
  final bool isActive;
  final String? notes;

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    return '$firstName $lastName'.trim();
  }

  String get summary {
    final parts = <String>[
      if (plateNumber.trim().isNotEmpty) plateNumber.trim(),
      if (maskedTckn.trim().isNotEmpty) maskedTckn.trim(),
    ];

    return parts.join(' - ');
  }

  factory DespatchDriverLookupItem.fromJson(JsonMap json) {
    return DespatchDriverLookupItem(
      id: _readString(json['id']),
      firstName: _readString(json['firstName']),
      lastName: _readString(json['lastName']),
      fullName: _readString(json['fullName']),
      plateNumber: _readString(json['plateNumber']),
      tckn: _readString(json['tckn']),
      maskedTckn: _readString(json['maskedTckn']),
      isActive: _readBool(json['isActive']),
      notes: _readNullableString(json['notes']),
    );
  }
}

String _readString(Object? value) => value?.toString().trim() ?? '';

String? _readNullableString(Object? value) {
  final normalized = value?.toString().trim() ?? '';

  return normalized.isEmpty ? null : normalized;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().trim().toLowerCase();

  return normalized == 'true' || normalized == '1';
}
