import 'package:clash_flt/clash_state.dart';
import 'package:clash_flt/entity/proxy.dart';
import "package:flutter/services.dart";

import 'entity/fetch_status.dart';
import 'entity/provider.dart';
import 'entity/proxy_group.dart';

class ClashFlt {
  static ClashFlt? _instance;
  static ClashFlt get instance => _instance ?? ClashFlt._();
  ClashFlt._() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final _channel = const MethodChannel("clash_flt");
  final Map<String, Function> _callbackPool = {};
  final state = ClashState();

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

  Future<void> fetchAndValid({
    required String path,
    required String url,
    required bool force,
    required Function(FetchStatus) reportStatus,
  }) async {
    const callbackKey = "fetchAndValid#reportStatus";
    _callbackPool[callbackKey] = reportStatus;
    await _channel.invokeMethod(
      "fetchAndValid",
      {
        "path": path,
        "url": url,
        "force": force,
        "callbackKey": callbackKey,
      },
    );
  }

  Future<void> load({required String path}) async {
    await _channel.invokeMethod("load", {"path": path});
  }

  Future<List<Provider>> queryProviders() async {
    final raw =
        await _channel.invokeListMethod<Map<String, dynamic>>("queryProviders");
    if (raw == null) return const [];
    return raw.map(Provider.fromJson).toList();
  }

  Future<List<String>> queryGroupNames({
    bool excludeNotSelectable = false,
  }) async {
    final raw = await _channel.invokeListMethod<String>(
      "queryGroupNames",
      {
        "excludeNotSelectable": excludeNotSelectable,
      },
    );
    return raw ?? const [];
  }

  Future<ProxyGroup?> queryGroup({
    required String name,
    ProxySort? proxySort,
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
    if (success) state.selectedProxy = proxy;
    return success;
  }

  Future<bool> startClash() async {
    return await _channel.invokeMethod("startClash") == true;
  }

  Future<void> stopClash() async {
    await _channel.invokeMethod("stopClash");
  }
}
