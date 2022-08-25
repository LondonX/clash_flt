import 'package:clash_flt/clash_flt.dart';
import 'package:clash_flt/entity/proxy.dart';
import 'package:clash_flt/entity/proxy_group.dart';
import 'package:clash_flt_example/proxy_view.dart';
import 'package:flutter/material.dart';

class NamedProxyGroupView extends StatefulWidget {
  final String groupName;

  const NamedProxyGroupView({
    Key? key,
    required this.groupName,
  }) : super(key: key);

  @override
  State<NamedProxyGroupView> createState() => _NamedProxyGroupViewState();
}

class _NamedProxyGroupViewState extends State<NamedProxyGroupView> {
  final _clash = ClashFlt.instance;
  ProxyGroup? _proxyGroup;
  Proxy? _selectedProxy;

  _load() async {
    final proxyGroup = await _clash.queryGroup(name: "Proxy");
    setState(() {
      _proxyGroup = proxyGroup;
    });
  }

  _toggleConnect(Proxy proxy) async {
    await _clash.patchSelector(
      widget.groupName,
      _selectedProxy == proxy ? null : proxy,
    );
  }

  _clashStateChange() {
    setState(() {
      _selectedProxy = _clash.state.selectedProxy;
    });
  }

  @override
  void initState() {
    _load();
    _clash.state.addListener(_clashStateChange);
    _clashStateChange();
    super.initState();
  }

  @override
  void dispose() {
    _clash.state.removeListener(_clashStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _proxyGroup?.proxies.length ?? 0,
      itemBuilder: _buildItem,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final proxy = _proxyGroup!.proxies[index];
    return ProxyView(
      proxy: proxy,
      isActived: _selectedProxy == proxy,
      onTap: _toggleConnect,
    );
  }
}
