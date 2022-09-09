import 'package:clash_flt/clash_state.dart';
import 'package:clash_flt/entity/proxy.dart';
import 'package:clash_flt/entity/traffic.dart';
import "package:flutter/services.dart";

import 'entity/log_mesage.dart';

class ClashChannel {
  static ClashChannel? _instance;
  static ClashChannel get instance => _instance ??= ClashChannel._();
  ClashChannel._() {
    _channel.setMethodCallHandler(_onMethodCall);
    _syncState();
  }

  final _channel = const MethodChannel("clash_flt");
  final Map<String, Function> _callbackPool = {};
  final state = ClashState();

  var _checkingHealth = false;
  get checkingHealth => _checkingHealth;

  _syncState() async {
    state.isRunning.value =
        await isClashRunning() ? Toggle.enabled : Toggle.disabled;
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    final arguments = call.arguments == null
        ? null
        : Map<String, dynamic>.from(call.arguments);
    final key = arguments?["callbackKey"];
    final callback = _callbackPool[key];
    if (callback == null) return;
    final rawParams = arguments?["params"];
    final jsonParams =
        rawParams is Map ? Map<String, dynamic>.from(rawParams) : null;
    switch (call.method) {
      case "callbackWithKey":
        callback.call(jsonParams);
        break;
    }
    return 1;
  }

  Future<Traffic> queryTrafficNow() async {
    final raw =
        await _channel.invokeMapMethod<String, dynamic>("queryTrafficNow");
    if (raw == null) return Traffic.zero;
    return Traffic.fromJson(raw);
  }

  Future<Traffic> queryTrafficTotal() async {
    final raw =
        await _channel.invokeMapMethod<String, dynamic>("queryTrafficTotal");
    if (raw == null) return Traffic.zero;
    return Traffic.fromJson(raw);
  }

  Future<void> healthCheck({required String name}) async {
    _checkingHealth = true;
    await _channel.invokeMethod("healthCheck", {"name": name});
    _checkingHealth = false;
  }

  Future<void> healthCheckAll() async {
    _checkingHealth = true;
    await _channel.invokeMethod("healthCheckAll");
    _checkingHealth = false;
  }

  Future<String> subscribeLogcat({
    required Function(LogMessage) onReceive,
    String callbackKey = "subscribeLogcat#onReceive",
  }) async {
    _callbackPool[callbackKey] = onReceive;
    await _channel.invokeMethod(
      "subscribeLogcat",
      {"callbackKey": callbackKey},
    );
    return callbackKey;
  }

  Future<void> unsubscribeLogcat({
    String callbackKey = "subscribeLogcat#onReceive",
  }) async {
    await _channel.invokeMethod(
      "unsubscribeLogcat",
      {"callbackKey": callbackKey},
    );
  }

  Future<bool> patchSelector(String groupName, Proxy? proxy) async {
    final success = await _channel.invokeMethod<bool>(
          "patchSelector",
          proxy == null
              ? null
              : {
                  "groupName": groupName,
                  ...proxy.toJson(),
                },
        ) ==
        true;
    if (success) state.selectedProxy.value = proxy;
    return success;
  }

  Future<bool> isClashRunning() async {
    return await _channel.invokeMethod("isClashRunning") == true;
  }

  Future<bool> startClash() async {
    state.isRunning.value = Toggle.enabling;
    final isStarted = await _channel.invokeMethod("startClash") == true;
    state.isRunning.value = isStarted ? Toggle.enabled : Toggle.disabled;
    return isStarted;
  }

  Future<void> stopClash() async {
    state.isRunning.value = Toggle.disabling;
    await _channel.invokeMethod("stopClash");
    state.isRunning.value = Toggle.disabled;
  }
}
