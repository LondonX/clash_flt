import 'package:clash_flt/clash_state.dart';
import 'package:clash_flt/entity/traffic.dart';
import "package:flutter/services.dart";

class ClashChannel {
  static ClashChannel? _instance;
  static ClashChannel get instance => _instance ??= ClashChannel._();
  ClashChannel._() {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final _channel = const MethodChannel("clash_flt");
  final Map<String, Function> _callbackPool = {};
  final state = ClashState();

  Future<void> syncState() async {
    state.isRunning.value =
        await isClashRunning() ? LazyState.enabled : LazyState.disabled;
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

  Future<bool> applyConfig(Map<String, dynamic> map) async {
    final success =
        await _channel.invokeMethod<bool>("applyConfig", map) == true;
    return success;
  }

  Future<bool> isClashRunning() async {
    return await _channel.invokeMethod("isClashRunning") == true;
  }

  Future<bool> startClash() async {
    state.isRunning.value = LazyState.enabling;
    final isStarted = await _channel.invokeMethod("startClash") == true;
    state.isRunning.value = isStarted ? LazyState.enabled : LazyState.disabled;
    return isStarted;
  }

  Future<void> stopClash() async {
    state.isRunning.value = LazyState.disabling;
    await _channel.invokeMethod("stopClash");
    state.isRunning.value = LazyState.disabled;
  }
}
