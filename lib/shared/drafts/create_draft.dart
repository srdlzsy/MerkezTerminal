class CreateDraft {
  const CreateDraft({
    required this.id,
    required this.moduleKey,
    required this.userId,
    required this.warehouseNo,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.payload,
  });

  final String id;
  final String moduleKey;
  final String userId;
  final String warehouseNo;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> payload;

  CreateDraft copyWith({
    String? title,
    DateTime? updatedAt,
    Map<String, dynamic>? payload,
  }) {
    return CreateDraft(
      id: id,
      moduleKey: moduleKey,
      userId: userId,
      warehouseNo: warehouseNo,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'moduleKey': moduleKey,
      'userId': userId,
      'warehouseNo': warehouseNo,
      'title': title,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'payload': payload,
    };
  }

  factory CreateDraft.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return CreateDraft(
      id: json['id']?.toString() ?? '',
      moduleKey: json['moduleKey']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      warehouseNo: json['warehouseNo']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      payload: switch (rawPayload) {
        final Map<String, dynamic> value => Map<String, dynamic>.from(value),
        final Map value => value.map(
          (key, item) => MapEntry(key.toString(), item),
        ),
        _ => <String, dynamic>{},
      },
    );
  }

  factory CreateDraft.empty({
    required String moduleKey,
    required String userId,
    required String warehouseNo,
    required String title,
  }) {
    final now = DateTime.now();
    return CreateDraft(
      id: '${now.microsecondsSinceEpoch}-$moduleKey',
      moduleKey: moduleKey,
      userId: userId,
      warehouseNo: warehouseNo,
      title: title,
      createdAt: now,
      updatedAt: now,
      payload: const <String, dynamic>{},
    );
  }
}
