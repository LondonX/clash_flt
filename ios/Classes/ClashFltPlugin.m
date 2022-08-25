#import "ClashFltPlugin.h"
#if __has_include(<clash_flt/clash_flt-Swift.h>)
#import <clash_flt/clash_flt-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "clash_flt-Swift.h"
#endif

@implementation ClashFltPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftClashFltPlugin registerWithRegistrar:registrar];
}
@end
