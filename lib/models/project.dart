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
}
