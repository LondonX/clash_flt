# clash_flt

A new Flutter plugin based on [ClashForAndroid](https://github.com/Kr328/ClashForAndroid) and [ClashX](https://github.com/yichengchen/clashX).

# Setup
### pubspec.yaml
```yaml
dependencies:
  clash_flt:
```
### Android
1. Requires minSdkVersion 21
2. Add `implementation files("ClashKit.aar")` in `<project-root>/android/app/build.gradle`'s dependencies section.
### iOS
1. Requires iOS 13 or newer.
2. As `gomobile` stop supporting armv7a, you need to exlude this architecture in XCode.
* Open `Runner.xcodeproj`, select `Runner` in `PROJECT` list on the left.
* In `Build Settings`->`All`->`Architectures`, set value to `arm64`.

3. Add `ClashKit.xcframework`
* Open `Pods` in Project Navigator.
* Select `clash_flt` in `TARGETS`
* Select `General` tab.
* Add `ClashKit.xcframework` into `Frameworks and Libraries`.

4. Modify `Runner.xcodeproj`
* Open `Signing & Capabilities` tab.
* You may need to enable `Network Extension` in [Apple Developer Account page](https://developer.apple.com/account/)/Certificates, IDs & Profiles/Identifiers/YOUR_BUNDLE_ID/Edit/Network Extensions checkbox, before add `Network Extension` and provision.
* Add `Network Extension` an `Personal VPN`.
* Check `App Proxy` and `Packet Tunnel` of `Network Extension`。

# Basic usage
### Fetch clash profile
```dart
final cacheDir = await getApplicationSupportDirectory();
// will save into this file
final profilesDir = Directory("${cacheDir.path}${Platform.pathSeparator}profiles");
await profilesDir.create(recursive: true);
await _clash.fetchAndValid(
    profilesDir: profilesDir,
    url: clashProfileUrl,
    force: true,
    reportStatus: (p0) {
    setState(() {
        _fetchStatus = p0;
    });
    },
);
setState(() {
    _fetchStatus = null;
});
```
### Load file of clash profile
```dart
await _clash.load(path: file.path);
```
### Get groupNames in profile
```dart
final groupNames = await _clash.queryGroupNames();
```
### Get proxyGroup by groupName
```dart
final proxyGroup = await _clash.queryGroup(name: groupName);
```
### Selet Proxy
```dart
await _clash.patchSelector(groupName, proxy);
```
### Start/Stop Clash VPN service
```dart
// start
_clash.startClash();
// stop
_clash.stopClash();
```

# Supported APIs
| API                       | Android | iOS |
| ------------------------- | ------- | --- |
| reset                     | ✅       | ❌   |
| forceGc                   | ✅       | ❌   |
| suspendCore               | ✅       | ❌   |
| queryTunnelState          | ✅       | ✅   |
| queryTrafficNow           | ✅       | ✅   |
| queryTrafficTotal         | ✅       | ✅   |
| notifyDnsChanged          | ✅       | ❌   |
| notifyTimeZoneChanged     | ✅       | ❌   |
| notifyInstalledAppChanged | ❌       | ❌   |
| startTun(startClash)      | ✅       |     |
| stopTun(stopClash)        | ✅       |     |
| startHttp(startClash)     | ✅       |     |
| stopHttp(stopClash)       | ✅       |     |
| queryGroupNames           | ✅       | ✅   |
| queryGroup                | ✅       | ✅   |
| healthCheck               | ✅       | ❌   |
| healthCheckAll            | ✅       | ❌   |
| patchSelector             | ✅       | ✅   |
| fetchAndValid             | ✅       | ✅   |
| load                      | ✅       | ✅   |
| queryProviders            | ✅       |     |
| updateProvider            | ✅       |     |
| queryOverride             | ❌       |     |
| writeOverride             | ❌       |     |
| clearOverride             | ❌       |     |
| installSideloadGeoip      | ✅       |     |
| queryConfiguration        | ❌       |     |
| subscribeLogcat           | ✅       |     |
| unsubscribeLogcat         | ✅       |     |