#include <WebViewApp.h>
#include <WebViewHandler.h>
#include <loop/platform/macos/App.h>
#include <webview.h>

#include <objc/runtime.h>

#include "include/cef_app.h"
#include "include/cef_application_mac.h"
#include "include/wrapper/cef_helpers.h"
#include "include/wrapper/cef_library_loader.h"

@interface CEFHelper : NSObject
+ (BOOL)start;
+ (void)stop;
@end

@implementation CEFHelper
+ (BOOL)start {
  NSApplication *app = [UApp sharedApplication];
  CHECK([NSApp isKindOfClass:[UApp class]]);

  CefScopedLibraryLoader library_loader;
  if (!library_loader.LoadInMain()) {
    return NO;
  }

  CefMainArgs main_args(0, NULL);

  CefSettings settings;
  settings.windowless_rendering_enabled = true;
  // TODO: get some option from zig build to toggle this
  settings.no_sandbox = true;

  CefRefPtr<WebViewApp> webview_app(new WebViewApp);

  if (!CefInitialize(main_args, settings, webview_app.get(), nullptr)) {
    return NO;
  }

  // Create handler singleton instance
  new WebViewHandler(true);

  return YES;
}

+ (void)stop {
  WebViewHandler *handler = WebViewHandler::GetInstance();
  CefShutdown();
}
@end

// There should only ever be 1 NSApplication ever created so this static prop
// should be ok
static BOOL _isHandlingEvent = NO;

@interface UApp (CEF) <CefAppProtocol>
@end

@implementation UApp (CEF)
+ (void)load {
  [CEFHelper start];
}

- (void)start {
  CefRunMessageLoop();
}

- (void)setHandlingSendEvent:(BOOL)handlingSendEvent {
  _isHandlingEvent = handlingSendEvent;
}

- (BOOL)isHandlingSendEvent {
  return _isHandlingEvent;
}

- (void)sendEvent:(NSEvent *)event {
  CefScopedSendingEvent sendingEventScoper;
  [super sendEvent:event];
}
@end
