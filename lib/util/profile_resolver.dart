import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:clash_flt/entity/profile.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:yaml/yaml.dart';

class ProfileResolver {
  static Future<Profile?> resolveProfile(File? file) async {
    if (file == null) return null;
    final receivePort = ReceivePort();
    Isolate.spawn<_ProfileResolve>(
      _resolve,
      _ProfileResolve(
        file: file,
        sendPort: receivePort.sendPort,
      ),
    );
    final result = await receivePort.first as Profile?;
    return result;
  }
}

_resolve(_ProfileResolve resolve) {
  final file = resolve.file;
  final sendPort = resolve.sendPort;
  try {
    final yaml = file.readAsStringSync();
    final parser = EmojiParser();
    final emojis = parser.parseEmojis(yaml).toSet();
    String unemojiYaml = yaml;
    for (var emoji in emojis) {
      final yamlSafeEmoji = parser.unemojify(emoji).replaceAll(":", "<EMOJI>");
      unemojiYaml = unemojiYaml.replaceAll(emoji, yamlSafeEmoji);
    }
    final YamlMap yamlMap = loadYaml(unemojiYaml, recover: true);
    final unemojiJson = json.encode(yamlMap);
    final emojiJson = parser.emojify(unemojiJson.replaceAll("<EMOJI>", ":"));
    final map = json.decode(emojiJson);
    map["file-path"] = file.path;
    sendPort.send(Profile.fromJson(map));
  } catch (e, stackTrace) {
    debugPrintStack(stackTrace: stackTrace);
  }
  sendPort.send(null);
}

class _ProfileResolve {
  final File file;
  final SendPort sendPort;
  const _ProfileResolve({
    required this.file,
    required this.sendPort,
  });
}
