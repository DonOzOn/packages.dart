#import "FlutterSmsPlugin.h"
#import <send_sms_handle/send_sms_handle-Swift.h>

@implementation FlutterSmsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterSmsPlugin registerWithRegistrar:registrar];
}
@end
