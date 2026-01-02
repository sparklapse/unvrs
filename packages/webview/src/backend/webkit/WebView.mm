#include <webview.h>

#import <WebKit/WebKit.h>
#include <string>

@interface WVMessageHandler : NSObject <WKScriptMessageHandler>
@end

@implementation WVMessageHandler
- (void)userContentController:
            (nonnull WKUserContentController *)userContentController
      didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
  if ([message.name isEqualToString:@"log"]) {
    NSLog(@"[js console] %@", message.body);
    return;
  }

  if ([message.name isEqualToString:@"ipc"]) {
    NSLog(@"Message was ipc");
    return;
  }
}
@end

u_webview_t u_webview_create(u_view_t view_ptr) {
  NSView *view = static_cast<NSView *>(view_ptr);
  WKWebViewConfiguration *wv_config = [WKWebViewConfiguration new];
  WKUserContentController *wv_ucc = [WKUserContentController new];

  // Message handler callbacks
  WVMessageHandler *mh = [WVMessageHandler new];
  [wv_ucc addScriptMessageHandler:mh name:@"log"];
  [wv_ucc addScriptMessageHandler:mh name:@"ipc"];

  // Logger bridge
  NSString *logger_js = @"(() => {"
                        @"  if (window.u_logger_bridge === true) return;"
                        @"  window.u_logger_bridge = true;"
                        @"  const { log: o_log } = window.console;"
                        @"  window.console.log = (...args) => {"
                        @"    window.webkit.messageHandlers.log.postMessage(args);"
                        @"    o_log(args);"
                        @"  };"
                        @"  o_log(\"log bridge registered - messages will be sent to stdout\");"
                        @"})()";

  WKUserScript *logger_script = [[WKUserScript alloc]
        initWithSource:logger_js
         injectionTime:WKUserScriptInjectionTimeAtDocumentStart
      forMainFrameOnly:YES];

  [wv_ucc addUserScript:logger_script];

  wv_config.userContentController = wv_ucc;

  // WebView
  WKWebView *wv = [[WKWebView alloc] initWithFrame:CGRectZero
                                     configuration:wv_config];

  wv.inspectable = YES;

  wv.translatesAutoresizingMaskIntoConstraints = NO;
  [view addSubview:wv];
  [NSLayoutConstraint activateConstraints:@[
    [wv.topAnchor constraintEqualToAnchor:view.topAnchor],
    [wv.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
    [wv.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
    [wv.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
  ]];

  return wv;
}

void u_webview_delete(u_webview_t self) {
  WKWebView *wv = static_cast<WKWebView *>(self);

  // TODO: message handler instance is removed but i dont think it gets dealloc
  // so creating and destroying many WebViews could cause memory leaking
  [wv.configuration.userContentController removeAllScriptMessageHandlers];

  // TODO: finish implement
}

void u_webview_load_url(u_webview_t self, uint8_t *url_ptr, size_t url_len) {
  WKWebView *wv = static_cast<WKWebView *>(self);
  NSString *url_str =
      [[NSString alloc] initWithBytes:reinterpret_cast<char *>(url_ptr)
                               length:url_len
                             encoding:[NSString defaultCStringEncoding]];

  NSURL *url = [NSURL URLWithString:url_str];
  NSURLRequest *request = [NSURLRequest requestWithURL:url];

  [wv loadRequest:request];
}

void u_webview_run_js(u_webview_t self, uint8_t *script_ptr,
                      size_t script_len) {
  WKWebView *wv = static_cast<WKWebView *>(self);

  NSString *script_str =
      [[NSString alloc] initWithBytes:reinterpret_cast<char *>(script_ptr)
                               length:script_len
                             encoding:[NSString defaultCStringEncoding]];

  [wv evaluateJavaScript:script_str
       completionHandler:^(id result, NSError *error) {
         if (error)
           NSLog(@"webview JS error: %@", error);
       }];
}
