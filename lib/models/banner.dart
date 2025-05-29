class Banner {
  final String id;
  final String url;

  Banner({
    required this.id,
    required this.url,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    // Ensure we have valid values for both id and url
    final id = json['id']?.toString();
    final url = json['url']?.toString();

    if (id == null || url == null) {
      throw FormatException('Invalid banner data: id or url is null');
    }

    return Banner(
      id: id,
      url: url,
    );
  }
}
