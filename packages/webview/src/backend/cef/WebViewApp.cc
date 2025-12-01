#include <webview.h>
#include "WebViewApp.h"
#include "WebViewHandler.h"

#include "include/cef_browser.h"
#include "include/cef_process_message.h"
#include "include/cef_v8.h"
#include "include/wrapper/cef_helpers.h"

WebViewApp::WebViewApp() = default;

void WebViewApp::OnContextInitialized() {
    CEF_REQUIRE_UI_THREAD();

    u_onContextInit();
}

CefRefPtr<CefClient> WebViewApp::GetDefaultClient() {
  return WebViewHandler::GetInstance();
}

bool WebViewApp::OnProcessMessageReceived(
    CefRefPtr<CefBrowser> browser, CefRefPtr<CefFrame> frame,
    CefProcessId source_process, CefRefPtr<CefProcessMessage> message) {
  CefString name = message->GetName();
  auto args = message->GetArgumentList();

  if (name == "js_set_string_value") {
    CEF_REQUIRE_RENDERER_THREAD();

    CefString key = args->GetString(0);
    CefString value = args->GetString(1);

    CefRefPtr<CefV8Context> context = frame->GetV8Context();
    context->Enter();

    CefRefPtr<CefV8Value> global = context->GetGlobal();
    CefRefPtr<CefV8Value> js_value = CefV8Value::CreateString(value);

    global->SetValue(key, js_value, V8_PROPERTY_ATTRIBUTE_NONE);

    context->Exit();
  }

  return false;
}
