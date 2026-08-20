class Country {
  const Country({required this.code, required this.name, required this.flag});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        code: json['code'] as String,
        name: json['name'] as String,
        flag: json['flag'] as String,
      );

  final String code;
  final String name;
  final String flag;

  Map<String, dynamic> toJson() => {'code': code, 'name': name, 'flag': flag};
}
