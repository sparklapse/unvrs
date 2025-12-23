#include "WebViewApp.h"
#include "WebViewHandler.h"
#include <webview.h>

#include "include/cef_browser.h"
// #include "include/cef_process_message.h"
#include "include/cef_v8.h"
#include "include/wrapper/cef_helpers.h"

WebViewApp::WebViewApp() = default;

CefRefPtr<CefClient> WebViewApp::GetDefaultClient() {
  return WebViewHandler::GetInstance();
}

void WebViewApp::OnContextInitialized() {
  CEF_REQUIRE_UI_THREAD();

  u_on_context_init();
}

void WebViewApp::OnContextCreated(CefRefPtr<CefBrowser> browser,
                                  CefRefPtr<CefFrame> frame,
                                  CefRefPtr<CefV8Context> context) {
  if (context->IsValid())
    u_on_context_create(context.get());
}
