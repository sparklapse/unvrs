#include "WebViewApp.h"
#include "WebViewHandler.h"

#include "include/cef_browser.h"
#include "include/wrapper/cef_helpers.h"

WebViewApp::WebViewApp() = default;

void WebViewApp::OnContextInitialized() {
  CEF_REQUIRE_UI_THREAD();
}
CefRefPtr<CefClient> WebViewApp::GetDefaultClient() {
  // Called when a new browser window is created via Chrome style UI.
  return WebViewHandler::GetInstance();
}
