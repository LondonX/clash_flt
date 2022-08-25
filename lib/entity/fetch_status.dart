import "package:json_annotation/json_annotation.dart";

part "fetch_status.g.dart";

@JsonSerializable()
class FetchStatus {
  FetchAction action;
  List<String> args;
  int progress;
  int max;
  FetchStatus({
    required this.action,
    required this.args,
    required this.progress,
    required this.max,
  });

  factory FetchStatus.fromJson(Map<String, dynamic> json) {
    return _$FetchStatusFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$FetchStatusToJson(this);
  }

  @override
  String toString() {
    return 'FetchStatus(action: $action, args: $args, progress: $progress, max: $max)';
  }
}

enum FetchAction {
  fetchConfiguration,
  fetchProviders,
  verifying,
}
