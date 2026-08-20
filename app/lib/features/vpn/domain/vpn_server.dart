class VpnServer {
  const VpnServer({
    required this.id,
    required this.name,
    required this.provider,
  });

  factory VpnServer.fromJson(Map<String, dynamic> json) => VpnServer(
        id: json['id'] as String,
        name: json['name'] as String,
        provider: json['provider'] as String,
      );

  final String id;
  final String name;
  final String provider;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider,
      };
}

class CountryServers {
  const CountryServers({
    required this.country,
    required this.servers,
  });

  factory CountryServers.fromJson(Map<String, dynamic> json) =>
      CountryServers(
        country: CountryInfo.fromJson(json['country'] as Map<String, dynamic>),
        servers: (json['servers'] as List)
            .map((s) => VpnServer.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  final CountryInfo country;
  final List<VpnServer> servers;
}

class CountryInfo {
  const CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
  });

  factory CountryInfo.fromJson(Map<String, dynamic> json) => CountryInfo(
        code: json['code'] as String,
        name: json['name'] as String,
        flag: json['flag'] as String,
      );

  final String code;
  final String name;
  final String flag;
}
