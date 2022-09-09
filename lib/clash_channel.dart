import 'dart:io';

import 'package:clash_flt/clash_state.dart';
import 'package:clash_flt/entity/proxy.dart';
import 'package:clash_flt/entity/traffic.dart';
import 'package:flutter/material.dart';
import "package:flutter/services.dart";

import 'entity/fetch_status.dart';
import 'entity/log_mesage.dart';
import 'entity/provider.dart';
import 'entity/proxy_group.dart';
import 'entity/tunnel_state.dart';

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
        final fetchStatus =
            jsonParams == null ? null : FetchStatus.fromJson(jsonParams);
        callback.call(fetchStatus);
        break;
    }
    return 1;
  }

  Future<void> reset() async {
    await _channel.invokeMethod("reset");
    state.selectedProxy.value = null;
  }

  Future<void> forceGc() async {
    await _channel.invokeMethod("forceGc");
  }

  Future<void> suspendCore({bool suspended = true}) async {
    await _channel.invokeMethod("suspendCore", {"suspended": suspended});
  }

  Future<TunnelState> queryTunnelState() async {
    final raw =
        await _channel.invokeMapMethod<String, dynamic>("queryTunnelState");
    if (raw == null) {
      return TunnelState(mode: TunnelStateMode.direct);
    }
    return TunnelState.fromJson(raw);
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

  Future<void> notifyDnsChanged({required List<String> dns}) async {
    await _channel.invokeMethod("notifyDnsChanged", {"dns": dns});
  }

  Future<void> notifyTimeZoneChanged({
    required String name,
    required int offset,
  }) async {
    await _channel.invokeMethod("notifyTimeZoneChanged", {
      "name": name,
      "offset": offset,
    });
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

  Future<void> installSideloadGeoip({required File file}) async {
    await _channel.invokeMethod("installSideloadGeoip", {"path": file.path});
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

  Future<void> fetchAndValid({
    required String url,
    required bool force,
    required Function(FetchStatus) reportStatus,
  }) async {
    const callbackKey = "fetchAndValid#reportStatus";
    _callbackPool[callbackKey] = reportStatus;
    try {
      await _channel.invokeMethod(
        "fetchAndValid",
        {
          "url": url,
          "force": force,
          "callbackKey": callbackKey,
        },
      );
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> load() async {
    await _channel.invokeMethod("load");
  }

  Future<List<Provider>> queryProviders() async {
    final raw =
        await _channel.invokeListMethod<Map<String, dynamic>>("queryProviders");
    if (raw == null) return const [];
    return raw.map(Provider.fromJson).toList();
  }

  Future<void> updateProvider({
    required ProviderType type,
    required String name,
  }) async {
    await _channel.invokeMethod("updateProvider", {
      "type": type.name,
      "name": name,
    });
  }

  Future<List<String>> queryGroupNames({
    bool excludeNotSelectable = false,
  }) async {
    final raw = await _channel.invokeListMethod<String>(
      "queryGroupNames",
      {"excludeNotSelectable": excludeNotSelectable},
    );
    return raw ?? const [];
  }

  Future<ProxyGroup?> queryGroup({
    required String name,
    dynamic? proxySort,
  }) async {
    final raw = await _channel.invokeMapMethod<String, dynamic>("queryGroup", {
      "name": name,
      "proxySort": proxySort,
    });
    if (raw == null) return null;
    return ProxyGroup.fromJson(raw);
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
