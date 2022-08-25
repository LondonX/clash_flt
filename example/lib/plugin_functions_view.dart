import 'package:clash_flt/clash_flt.dart';
import 'package:clash_flt/clash_state.dart';
import 'package:clash_flt/entity/tunnel_state.dart';
import 'package:flutter/material.dart';

class PluginFunctionsView extends StatefulWidget {
  const PluginFunctionsView({Key? key}) : super(key: key);

  @override
  State<PluginFunctionsView> createState() => _PluginFunctionsViewState();
}

class _PluginFunctionsViewState extends State<PluginFunctionsView> {
  final _clash = ClashFlt.instance;
  TunnelState? _tunnelState;
  int? _trafficNow;
  int? _trafficTotal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ValueListenableBuilder<Toggle>(
          valueListenable: _clash.state.isRunning,
          builder: (context, value, child) {
            return SwitchListTile(
              title: const Text("VPN enabled"),
              subtitle: const Text("Clash.startClash | Clash.stopClash"),
              value: value == Toggle.enabled || value == Toggle.disabling,
              onChanged: value == Toggle.enabling || value == Toggle.disabling
                  ? null
                  : (v) {
                      if (v) {
                        _clash.startClash();
                      } else {
                        _clash.stopClash();
                      }
                    },
            );
          },
        ),
        ListTile(
          title: const Text("Reset"),
          subtitle: const Text("Clash.reset"),
          onTap: _clash.reset,
        ),
        ListTile(
          title: const Text("Force GC"),
          subtitle: const Text("Clash.forceGc"),
          onTap: _clash.forceGc,
        ),
        ListTile(
          title: const Text("Query tunnel state"),
          subtitle: _tunnelState == null
              ? const Text("Clash.queryTunnelState")
              : Text(_tunnelState!.mode.name),
          onTap: () async {
            final result = await _clash.queryTunnelState();
            setState(() {
              _tunnelState = result;
            });
          },
        ),
        ListTile(
          title: const Text("Query traffic now"),
          subtitle: _trafficNow == null
              ? const Text("Clash.queryTrafficNow")
              : Text(_trafficNow.toString()),
          onTap: () async {
            final result = await _clash.queryTrafficNow();
            setState(() {
              _trafficNow = result;
            });
          },
        ),
        ListTile(
          title: const Text("Query traffic total"),
          subtitle: _trafficTotal == null
              ? const Text("Clash.queryTrafficTotal")
              : Text(_trafficTotal.toString()),
          onTap: () async {
            final result = await _clash.queryTrafficTotal();
            setState(() {
              _trafficTotal = result;
            });
          },
        ),
        ListTile(
          title: const Text("Health check all"),
          subtitle: const Text("Clash.healthCheckAll"),
          onTap: _clash.healthCheckAll,
        ),
      ],
    );
  }
}
