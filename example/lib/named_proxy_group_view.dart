import 'package:clash_flt/clash_flt.dart';
import 'package:clash_flt/entity/proxy.dart';
import 'package:clash_flt/entity/proxy_group.dart';
import 'package:clash_flt_example/proxy_view.dart';
import 'package:flutter/material.dart';

class NamedProxyGroupView extends StatefulWidget {
  final ProxyGroup group;

  const NamedProxyGroupView({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  State<NamedProxyGroupView> createState() => _NamedProxyGroupViewState();
}

class _NamedProxyGroupViewState extends State<NamedProxyGroupView> {
  final _proxies = <Proxy>[];

  _selectProxy(Proxy proxy) {
    setState(() {
      ClashFlt.instance.selectProxy(widget.group, proxy);
    });
  }

  _healthCheck(Proxy proxy) async {
    await ClashFlt.instance.healthCheck(proxy);
    setState(() {});
  }

  _mapProxies() {
    final proxies =
        widget.group.proxies.map((e) => ClashFlt.instance.findProxy(e));
    setState(() {
      _proxies
        ..clear()
        ..addAll(proxies);
    });
  }

  @override
  void initState() {
    _mapProxies();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant NamedProxyGroupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _mapProxies();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _proxies.length,
      itemBuilder: _buildItem,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final proxy = _proxies[index];
    final isSelected = ClashFlt.instance.isProxySelected(widget.group, proxy);
    final isSelectable =
        ClashFlt.instance.isProxySelectable(widget.group, proxy);
    return ProxyView(
      proxy: proxy,
      isActived: isSelected,
      onTap: isSelectable ? _selectProxy : null,
      healthCheck: _healthCheck,
    );
  }
}
