class Banner {
  final String id;
  final String title;
  final String code;
  final String description;
  final String? url;
  final String isPublish;
  final String type;
  final String imagePath;

  Banner({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    this.url,
    required this.isPublish,
    required this.type,
    required this.imagePath,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      url: json['url']?.toString(),
      isPublish: json['is_publish']?.toString() ?? '0',
      type: json['type']?.toString() ?? '',
      imagePath: json['image']?['path']?.toString() ?? '',
    );
  }
}
