import 'package:clash_flt/entity/proxy.dart';
import 'package:flutter/material.dart';

class ProxyView extends StatelessWidget {
  final Proxy proxy;
  final bool isActive;
  final Function(Proxy)? onTap;
  final Function(Proxy) healthCheck;
  const ProxyView({
    Key? key,
    required this.proxy,
    required this.isActive,
    required this.onTap,
    required this.healthCheck,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                onTap!(proxy);
              },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(proxy.name),
                    const SizedBox(height: 8),
                    Text(proxy.type, style: textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(
                      proxy.delay == null
                          ? ""
                          : "${proxy.delay!.inMilliseconds}ms",
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  healthCheck(proxy);
                },
                icon: const Icon(Icons.timer_outlined),
              ),
              if (isActive)
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
