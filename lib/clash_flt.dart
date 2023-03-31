import 'dart:convert';
import 'dart:io';

import 'package:clash_flt/clash_channel.dart';
import 'package:clash_flt/entity/proxy_group.dart';
import 'package:clash_flt/util/health_checker.dart';
import 'package:clash_flt/util/profile_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'clash_state.dart';
import 'entity/profile.dart';
import 'entity/proxy.dart';
import 'entity/traffic.dart';

export 'entity/profile.dart';

class ClashFlt {
  static ClashFlt? _instance;
  static ClashFlt get instance => _instance ??= ClashFlt._();

  Directory homeDir = Directory("");

  final profileFile = ValueNotifier<File?>(null);
  final profileDownloading = ValueNotifier<bool>(false);
  final countryDBFile = ValueNotifier<File?>(null);
  final countryDBDownloading = ValueNotifier<bool>(false);
  final profile = ValueNotifier<Profile?>(null);
  final profileResolving = ValueNotifier<bool>(false);
  final healthChecking = ValueNotifier<bool>(false);

  ///
  /// DO NOT set value, call `selectProxy` instead
  ///
  final selectedProxyGroupName = ValueNotifier<String?>(null);

  ///
  /// DO NOT set value, call `selectProxy` instead
  ///
  final selectedProxyName = ValueNotifier<String?>(null);

  ///
  /// [allowStartFromIOSSettings] Allow VPN start from ios System Settings.
  /// Only works on iOS, Android doesn't support start custom VPN from system preference.
  /// Default is true
  ///
  bool allowStartFromIOSSettings = true;

  final _channel = ClashChannel.instance;
  ClashState get state => _channel.state;

  Future<void> init(Directory homeDir) async {
    this.homeDir = homeDir;
    await _channel.syncState();
    HealthChecker.init();
  }

  ClashFlt._();

  Future<bool> downloadProfile(String url, {bool isForce = false}) async {
    final uri = Uri.parse(url);
    final fileName = url.split("/").last;
    File target = File(
      "${homeDir.path}${Platform.pathSeparator}profile${Platform.pathSeparator}$fileName",
    );
    if (await target.exists() && !isForce) {
      profileFile.value = target;
      return true;
    }
    profileDownloading.value = true;
    await target.create(recursive: true);
    final downloaded = await _download(uri, target);
    profileDownloading.value = false;
    if (downloaded) {
      profileFile.value = target;
      return true;
    }
    return false;
  }

  Future<bool> resolveProfile([File? file]) async {
    final safeFile = file ?? profileFile.value;
    profileResolving.value = true;
    profile.value = await ProfileResolver.resolveProfile(safeFile);
    profileResolving.value = false;
    if (profile.value == null) return false;
    //update defaultSelection
    final currentProxyName = selectedProxyName.value;
    final proxies = profile.value?.proxies ?? [];
    final hasProxy = proxies.any((element) => element.name == currentProxyName);
    if (!hasProxy) {
      final defaultGroup = _findUrlTestGroup();
      selectedProxyGroupName.value = defaultGroup?.name;
      selectedProxyName.value = defaultGroup?.name;
    }
    _applyConfig();
    return profile.value != null;
  }

  Future<void> polluteCountryDB(String assetName) async {
    countryDBDownloading.value = true;
    final data = await rootBundle.load(assetName);
    File target = File(
      "${homeDir.path}${Platform.pathSeparator}Country.mmdb",
    );
    if (!await target.exists()) await target.create(recursive: true);
    await target.writeAsBytes(data.buffer.asUint8List());
    countryDBDownloading.value = false;
    countryDBFile.value = target;
  }

  Future<bool> downloadCountryDB({
    String url =
        "https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb",
    bool isForce = false,
  }) async {
    final uri = Uri.parse(url);
    final fileName = url.split("/").last;
    File target = File(
      "${homeDir.path}${Platform.pathSeparator}$fileName",
    );
    if (await target.exists() && !isForce) {
      countryDBFile.value = target;
      return true;
    }
    countryDBDownloading.value = true;
    await target.create(recursive: true);
    final downloaded = await _download(uri, target);
    countryDBDownloading.value = false;
    if (downloaded) {
      countryDBFile.value = target;
      return true;
    }
    return false;
  }

  Proxy? findProxyOrNull(String name) {
    try {
      return findProxy(name);
    } catch (_) {}
    return null;
  }

  Proxy findProxy(String name) {
    final proxyGroups = profile.value?.proxyGroups ?? [];
    try {
      final group = proxyGroups.firstWhere((element) => element.name == name);
      return Proxy(name: group.name, type: "url-test", server: "");
    } catch (_) {}
    final proxies = profile.value?.proxies ?? [];
    return proxies.firstWhere((element) => element.name == name);
  }

  Future<bool> healthCheck(Proxy proxy) async {
    healthChecking.value = true;
    await HealthChecker.healthCheck(proxy);
    healthChecking.value = false;
    return proxy.delay != null;
  }

  Future<bool> healthCheckAll() async {
    if (healthChecking.value) return false;
    final proxies = profile.value?.proxies;
    if (proxies == null) return false;
    if (proxies.isEmpty) return true;
    healthChecking.value = true;
    await HealthChecker.healthCheckAll(proxies);
    healthChecking.value = false;
    return true;
  }

  selectProxy(ProxyGroup group, Proxy proxy) {
    if (group.type.toLowerCase() == "url-test") return;
    if (proxy.type.toLowerCase() == "url-test") {
      final urlTestGroup = _findUrlTestGroup();
      if (urlTestGroup == null) return;
      selectedProxyGroupName.value = urlTestGroup.name;
    } else {
      selectedProxyGroupName.value = group.name;
    }
    selectedProxyName.value = proxy.name;
    _applyConfig();
  }

  bool isProxySelectable(ProxyGroup group, Proxy proxy) {
    if (group.type.toLowerCase() == "url-test") {
      return false;
    }
    return true;
  }

  bool isProxySelected(ProxyGroup group, Proxy proxy) {
    if (selectedProxyName.value != proxy.name) return false;
    if (proxy.type.toLowerCase() == "url-test") {
      return selectedProxyGroupName.value == proxy.name;
    }
    return selectedProxyGroupName.value == group.name;
  }

  Future<bool> startClash() async {
    final applied = await _applyConfig();
    if (!applied) return false;
    return await _channel.startClash();
  }

  Future<void> stopClash() async {
    await _channel.stopClash();
  }

  Future<void> includeAndroidApps(Set<String> packages) async {
    await _channel.includeAndroidApps(packages);
  }

  Future<Traffic> queryTrafficNow() {
    return _channel.queryTrafficNow();
  }

  Future<Traffic> queryTrafficTotal() {
    return _channel.queryTrafficTotal();
  }

  Future<bool> _applyConfig() async {
    final clashHome = homeDir.path;
    final profilePath = profile.value?.filePath;
    final countryDBPath = countryDBFile.value?.path;
    final groupName = selectedProxyGroupName.value;
    final proxyName = selectedProxyName.value;
    if (profilePath == null) {
      _debugPrint("[ClashFlt]applyConfig failed!!! profilePath is null.");
      return false;
    }
    if (countryDBPath == null) {
      _debugPrint("[ClashFlt]applyConfig failed!!! countryDBPath is null.");
      return false;
    }
    if (groupName == null) {
      _debugPrint("[ClashFlt]applyConfig failed!!! groupName is null.");
      return false;
    }
    if (proxyName == null) {
      _debugPrint("[ClashFlt]applyConfig failed!!! proxyName is null.");
      return false;
    }
    final map = {
      "clashHome": clashHome,
      "profilePath": profilePath,
      "countryDBPath": countryDBPath,
      "groupName": groupName,
      "proxyName": proxyName,
      "allowStartFromIOSSettings": allowStartFromIOSSettings,
    };
    final cfgJson = json.encode(map);
    _debugPrint("[ClashFlt]applyConfig: $cfgJson");
    _channel.applyConfig(map);
    return true;
  }

  ProxyGroup? _findUrlTestGroup() {
    final groups = profile.value?.proxyGroups ?? [];
    try {
      return groups
          .firstWhere((element) => element.type.toLowerCase() == "url-test");
    } catch (_) {}
    return null;
  }
}

HttpClient _httpClient = HttpClient()
  ..connectionTimeout = const Duration(seconds: 20);
Future<bool> _download(Uri uri, File file) async {
  try {
    var request = await _httpClient.getUrl(uri);
    var response = await request.close();
    if (response.statusCode ~/ 100 == 2) {
      var bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);
      return true;
    } else {
      _debugPrint("[ClashFlt]Download failed status: ${response.statusCode}");
      return false;
    }
  } catch (ex, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}

_debugPrint(Object? obj) {
  if (kReleaseMode) return;
  // ignore: avoid_print
  print(obj);
}
