import 'package:flutter/material.dart';

import 'entity/proxy.dart';

class ClashState extends ChangeNotifier {
  Proxy? _selectedProxy;
  set selectedProxy(Proxy? target) {
    if (_selectedProxy == target) return;
    _selectedProxy = target;
    notifyListeners();
  }

  Proxy? get selectedProxy => _selectedProxy;
}
