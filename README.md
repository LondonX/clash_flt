# clash_flt

A new Flutter plugin based on [ClashForAndroid](https://github.com/Kr328/ClashForAndroid) and [ClashX](https://github.com/yichengchen/clashX).

# Setup
### pubspec.yaml
```yaml
dependencies:
  clash_flt:
```
### Android
*No additional opereates*
### iOS
As `gomobile` stop supporting armv7a, you need to exlude this architecture in XCode.
* Open `Runner.xcodeproj`, select `Runner` in `PROJECT` list on the left.
* In `Build Settings`->`All`->`Architectures`, set value to `arm64`.

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
| API                       | Android       | iOS |
| ------------------------- | ------------- | --- |
| reset                     | ✅             |     |
| forceGc                   | ✅             |     |
| suspendCore               | ✅             |     |
| queryTunnelState          | ✅             |     |
| queryTrafficNow           | ✅             |     |
| queryTrafficTotal         | ✅             |     |
| notifyDnsChanged          | ✅             |     |
| notifyTimeZoneChanged     | ✅             |     |
| notifyInstalledAppChanged | ❌             |     |
| startTun                  | ✅(startClash) |     |
| stopTun                   | ✅(stopClash)  |     |
| startHttp                 | ✅(startClash) |     |
| stopHttp                  | ✅(stopClash)  |     |
| queryGroupNames           | ✅             |     |
| queryGroup                | ✅             |     |
| healthCheck               | ✅             |     |
| healthCheckAll            | ✅             |     |
| patchSelector             | ✅             |     |
| fetchAndValid             | ✅             |     |
| load                      | ✅             |     |
| queryProviders            | ✅             |     |
| updateProvider            | ✅             |     |
| queryOverride             | ❌             |     |
| writeOverride             | ❌             |     |
| clearOverride             | ❌             |     |
| installSideloadGeoip      | ✅             |     |
| queryConfiguration        | ❌             |     |
| subscribeLogcat           | ✅             |     |
| unsubscribeLogcat         | ✅             |     |