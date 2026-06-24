import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  final PackageInfo _info;

  AppInfoService._(this._info);

  static Future<AppInfoService> create() async {
    final info = await PackageInfo.fromPlatform();
    return AppInfoService._(info);
  }

  String get appName => _info.appName;
  String get packageName => _info.packageName;
  String get version => _info.version;
  String get buildNumber => _info.buildNumber;
  String get versionLabel => 'v$version+$buildNumber';
}
