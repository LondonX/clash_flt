import 'dart:io';

import 'package:clash_flt/clash_flt.dart';
import 'package:clash_flt/clash_state.dart';
import 'package:clash_flt/entity/traffic.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'sensitive_info.dart';

class PluginFunctionsView extends StatefulWidget {
  const PluginFunctionsView({Key? key}) : super(key: key);

  @override
  State<PluginFunctionsView> createState() => _PluginFunctionsViewState();
}

class _PluginFunctionsViewState extends State<PluginFunctionsView> {
  bool _clashInited = false;

  Traffic _trafficNow = Traffic.zero;
  Traffic _trafficTotal = Traffic.zero;

  _initClash() async {
    final filesDir = await getApplicationSupportDirectory();
    final clashHome =
        Directory("${filesDir.path}${Platform.pathSeparator}clash");
    await clashHome.create();
    await ClashFlt.instance.init(clashHome);
    setState(() {
      _clashInited = true;
    });
  }

  @override
  void initState() {
    _initClash();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!_clashInited) {
      return const Center(child: Text("Initializing ClashFlt"));
    }
    return ListView(
      children: [
        ValueListenableBuilder<File?>(
          valueListenable: ClashFlt.instance.profileFile,
          builder: (context, profileFile, child) {
            return ListTile(
              title: const Text("Download Profile"),
              subtitle: ValueListenableBuilder<bool>(
                valueListenable: ClashFlt.instance.profileDownloading,
                builder: (context, isDownloading, child) {
                  return Text(
                    isDownloading
                        ? "Downloading"
                        : profileFile == null
                            ? "ClashFlt.downloadProfile"
                            : "${getFileName(profileFile)} Downloaded✅",
                  );
                },
              ),
              onTap: () {
                ClashFlt.instance.downloadProfile(
                  clashProfileUrl,
                  isForce: true,
                );
              },
            );
          },
        ),
        ValueListenableBuilder<File?>(
          valueListenable: ClashFlt.instance.countryDBFile,
          builder: (context, countryDBFile, child) {
            return ListTile(
              title: const Text("Download Country DB"),
              subtitle: ValueListenableBuilder<bool>(
                valueListenable: ClashFlt.instance.countryDBDownloading,
                builder: (context, isDownloading, child) {
                  return Text(
                    isDownloading
                        ? "Downloading"
                        : countryDBFile == null
                            ? "ClashFlt.downloadCountryDB"
                            : "${getFileName(countryDBFile)} Downloaded✅",
                  );
                },
              ),
              onTap: () {
                ClashFlt.instance.downloadCountryDB(isForce: true);
              },
            );
          },
        ),
        ListTile(
          title: const Text("Download CountryDB from assets"),
          subtitle: const Text("ClashFlt.polluteCountryDB"),
          onTap: () async {
            ClashFlt.instance.polluteCountryDB("assets/Country.mmdb");
          },
        ),
        ValueListenableBuilder<Profile?>(
          valueListenable: ClashFlt.instance.profile,
          builder: (context, profile, child) {
            return ListTile(
              title: const Text("Resolve profile"),
              subtitle: ValueListenableBuilder<bool>(
                valueListenable: ClashFlt.instance.profileResolving,
                builder: (context, isResolving, child) {
                  return Text(
                    isResolving
                        ? "Resolving"
                        : profile == null
                            ? "ClashFlt.resolveProfile"
                            : "Resolved ${profile.proxies.length} proxy(s) & ${profile.proxyGroups.length} group(s)✅",
                  );
                },
              ),
              onTap: () {
                ClashFlt.instance.resolveProfile();
              },
            );
          },
        ),
        ListTile(
          title: const Text("Health Check"),
          subtitle: ValueListenableBuilder<bool>(
            valueListenable: ClashFlt.instance.healthChecking,
            builder: (context, isChecking, child) {
              return Text(
                isChecking ? "Checking" : "ClashFlt.healthCheckAll",
              );
            },
          ),
          onTap: () {
            ClashFlt.instance.healthCheckAll();
          },
        ),
        ValueListenableBuilder<LazyState>(
          valueListenable: ClashFlt.instance.state.isRunning,
          builder: (context, value, child) {
            return SwitchListTile(
              title: const Text("VPN enabled"),
              subtitle: const Text("ClashFlt.startClash | ClashFlt.stopClash"),
              value: value == LazyState.enabled || value == LazyState.disabling,
              onChanged:
                  value == LazyState.enabling || value == LazyState.disabling
                      ? null
                      : (v) {
                          if (v) {
                            ClashFlt.instance.startClash();
                          } else {
                            ClashFlt.instance.stopClash();
                          }
                        },
            );
          },
        ),
      ],
    );
  }
}

String getFileName(File file) {
  final separator = Platform.pathSeparator;
  return file.path.split(separator).last;
}
