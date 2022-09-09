import 'package:flutter/material.dart';

class ClashState {
  final isRunning = ValueNotifier<LazyState>(LazyState.enabling);
}

enum LazyState {
  enabled,
  disabled,
  enabling,
  disabling,
}
