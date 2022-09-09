import 'dart:convert';
import 'dart:io';

import 'package:clash_flt/entity/profile.dart';
import 'package:clash_flt/entity/proxy.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:yaml/yaml.dart';

export 'entity/profile.dart';

class ClashFlt {
  static ClashFlt? _instance;
  static ClashFlt get instance => _instance ??= ClashFlt._();

  late final Directory homeDir;

  final profileFile = ValueNotifier<File?>(null);
  final profileDownloading = ValueNotifier<bool>(false);
  final countryDBFile = ValueNotifier<File?>(null);
  final countryDBDownloading = ValueNotifier<bool>(false);
  final profile = ValueNotifier<Profile?>(null);
  final profileResolving = ValueNotifier<bool>(false);

  init(Directory homeDir) {
    this.homeDir = homeDir;
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
    final profileFileValue = file ?? profileFile.value;
    if (profileFileValue == null) return false;
    profileResolving.value = true;
    try {
      final yaml = await profileFileValue.readAsString();
      final parser = EmojiParser();
      final emojis = parser.parseEmojis(yaml).toSet();
      String unemojiYaml = yaml;
      for (var emoji in emojis) {
        final yamlSafeEmoji =
            parser.unemojify(emoji).replaceAll(":", "<EMOJI>");
        unemojiYaml = unemojiYaml.replaceAll(emoji, yamlSafeEmoji);
      }
      final YamlMap yamlMap = loadYaml(unemojiYaml, recover: true);
      final unemojiJson = json.encode(yamlMap);
      final emojiJson = parser.emojify(unemojiJson.replaceAll("<EMOJI>", ":"));
      final map = json.decode(emojiJson);
      map["file-path"] = profileFileValue.path;
      profile.value = Profile.fromJson(map);
      profileResolving.value = false;
      return true;
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
    }
    profileResolving.value = false;
    return false;
  }

  Future<File> polluteCountryDB(String assetName) async {
    countryDBDownloading.value = true;
    final data = await rootBundle.load(assetName);
    File target = File(
      "${homeDir.path}${Platform.pathSeparator}country${Platform.pathSeparator}Country.mmdb",
    );
    if (!await target.exists()) target.create(recursive: true);
    await target.writeAsBytes(data.buffer.asUint8List());
    countryDBDownloading.value = false;
    return target;
  }

  Future<File?> downloadCountryDB({
    String url =
        "https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb",
    bool isForce = false,
  }) async {
    final uri = Uri.parse(url);
    final fileName = url.split("/").last;
    File target = File(
      "${homeDir.path}${Platform.pathSeparator}country${Platform.pathSeparator}$fileName",
    );
    if (await target.exists() && !isForce) {
      return target;
    }
    countryDBDownloading.value = true;
    await target.create(recursive: true);
    final downloaded = await _download(uri, target);
    countryDBDownloading.value = false;
    if (downloaded) {
      return target;
    }
    return null;
  }

  Proxy findProxy(String name) {
    final proxies = profile.value?.proxies ?? [];
    return proxies.firstWhere((element) => element.name == name);
  }
}

Future<bool> _download(Uri uri, File file) async {
  try {
    HttpClient httpClient = HttpClient();
    httpClient.connectionTimeout = const Duration(seconds: 20);
    var request = await httpClient.getUrl(uri);
    var response = await request.close();
    if (response.statusCode ~/ 100 == 2) {
      var bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);
      return true;
    } else {
      if (kDebugMode) {
        print("[ClashFlt]Download failed status: ${response.statusCode}");
      }
      return false;
    }
  } catch (ex, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
    return false;
  }
}
