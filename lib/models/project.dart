class Project {
  final String id;
  final String name;
  final String client;
  final String status;
  final String owner;
  final DateTime? dueDate;

  const Project({
    required this.id,
    required this.name,
    required this.client,
    required this.status,
    required this.owner,
    this.dueDate,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      client: (json['client'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      owner: (json['owner'] ?? '').toString(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'client': client,
        'status': status,
        'owner': owner,
        'dueDate': dueDate?.toIso8601String(),
      };

  Project copyWith({
    String? id,
    String? name,
    String? client,
    String? status,
    String? owner,
    DateTime? dueDate,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      client: client ?? this.client,
      status: status ?? this.status,
      owner: owner ?? this.owner,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
