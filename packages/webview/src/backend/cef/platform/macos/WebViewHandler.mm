#include "WebViewHandler.h"

#import <Cocoa/Cocoa.h>

#include "include/cef_browser.h"

namespace {

NSWindow* GetNSWindowForBrowser(CefRefPtr<CefBrowser> browser) {
  NSView* view =
      CAST_CEF_WINDOW_HANDLE_TO_NSVIEW(browser->GetHost()->GetWindowHandle());
  return [view window];
}

}  // namespace

void WebViewHandler::PlatformTitleChange(CefRefPtr<CefBrowser> browser,
                                        const CefString& title) {
  // NSWindow* window = GetNSWindowForBrowser(browser);
  // std::string titleStr(title);
  // NSString* str = [NSString stringWithUTF8String:titleStr.c_str()];
  // [window setTitle:str];
}

void WebViewHandler::PlatformShowWindow(CefRefPtr<CefBrowser> browser) {
  NSWindow* window = GetNSWindowForBrowser(browser);
  [window makeKeyAndOrderFront:window];
}
