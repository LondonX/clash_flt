import 'package:clash_flt/clash_flt.dart';
import 'package:clash_flt/clash_state.dart';
import 'package:flutter/material.dart';

class PluginFunctionsView extends StatefulWidget {
  const PluginFunctionsView({Key? key}) : super(key: key);

  @override
  State<PluginFunctionsView> createState() => _PluginFunctionsViewState();
}

class _PluginFunctionsViewState extends State<PluginFunctionsView> {
  final _clash = ClashFlt.instance;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

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
      ],
    );
  }
}
