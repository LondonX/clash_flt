import 'package:clash_flt/clash_flt.dart';
import 'package:clash_flt/entity/proxy_group.dart';
import 'package:clash_flt_example/named_proxy_group_view.dart';
import 'package:clash_flt_example/plugin_functions_view.dart';
import 'package:flutter/material.dart';

class PluginExample extends StatefulWidget {
  const PluginExample({Key? key}) : super(key: key);

  @override
  State<PluginExample> createState() => _PluginExampleState();
}

class _PluginExampleState extends State<PluginExample>
    with TickerProviderStateMixin {
  final _groups = <ProxyGroup>[];

  late TabController _uiTab = TabController(length: 1, vsync: this);

  _profileChange() {
    final groups = ClashFlt.instance.profile.value?.proxyGroups ?? [];
    setState(() {
      _groups
        ..clear()
        ..addAll(groups);
    });
    _uiTab = TabController(length: 1 + groups.length, vsync: this);
  }

  @override
  void initState() {
    ClashFlt.instance.profile.addListener(_profileChange);
    super.initState();
  }

  @override
  void dispose() {
    _uiTab.dispose();
    super.dispose();
    ClashFlt.instance.profile.removeListener(_profileChange);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("clash_flt"),
        bottom: TabBar(
          tabs: [
            "Plugin Functions",
            ..._groups.map((e) => e.name),
          ].map((e) => Tab(text: e)).toList(),
          controller: _uiTab,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          TabBarView(
            controller: _uiTab,
            children: [
              const PluginFunctionsView(),
              ..._groups.map((e) => NamedProxyGroupView(group: e))
            ],
          ),
        ],
      ),
    );
  }
}
