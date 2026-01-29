#import <Foundation/Foundation.h>
#import <dlfcn.h>


/// Helper class to enable accessibility. Without this, many of the accessibility properties will return `nil` when the
/// value isn't explicitly set. Accessibility is enabled when this class is loaded into the runtime, so any target that
/// imports AccessibilitySnapshot will automatically have accessibility enabled.
///
/// This is based on the KIFEnableAccessibility() function from the KIF framework.
@interface ASAccessibilityEnabler : NSObject

@end


@implementation ASAccessibilityEnabler

+ (void)load;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *handle = [self loadDylib:@"/usr/lib/libAccessibility.dylib"];
        if (!handle) {
            [NSException raise:NSGenericException format:@"Could not enable accessibility"];
        }

        int (*_AXSAutomationEnabled)(void) = dlsym(handle, "_AXSAutomationEnabled");
        void (*_AXSSetAutomationEnabled)(int) = dlsym(handle, "_AXSSetAutomationEnabled");

        int initialValue = _AXSAutomationEnabled();
        _AXSSetAutomationEnabled(YES);
        atexit_b(^{
            _AXSSetAutomationEnabled(initialValue);
        });
    });
}

+ (void *)loadDylib:(NSString *_Nonnull)path;
{
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSString *simulatorRoot = [environment objectForKey:@"IPHONE_SIMULATOR_ROOT"];
    if (simulatorRoot) {
        path = [simulatorRoot stringByAppendingPathComponent:path];
    }
    return dlopen([path fileSystemRepresentation], RTLD_LOCAL);
}

@end
