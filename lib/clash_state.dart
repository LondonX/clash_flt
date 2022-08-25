import 'package:flutter/material.dart';

import 'entity/proxy.dart';

class ClashState {
  final isRunning = ValueNotifier<Toggle>(Toggle.enabling);
  final selectedProxy = ValueNotifier<Proxy?>(null);
}

enum Toggle {
  enabled,
  disabled,
  enabling,
  disabling,
}
