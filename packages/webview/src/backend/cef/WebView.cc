#include <webview.h>

#include "include/cef_browser.h"
#include "include/wrapper/cef_helpers.h"

#include "WebViewHandler.h"

u_webview_t u_webview_create(u_view_t view, int32_t width, int32_t height,
                             uint8_t *url) {
  CEF_REQUIRE_UI_THREAD();

  // SimpleHandler implements browser-level callbacks.
  CefRefPtr<WebViewHandler> handler(WebViewHandler::GetInstance());

  // Specify CEF browser settings here.
  CefBrowserSettings browser_settings;
  browser_settings.background_color = CefColorSetARGB(255, 0, 0, 0);

  std::string url_str(reinterpret_cast<char *>(url));

  CefWindowInfo window_info;
  window_info.SetAsChild(view, CefRect(0, 0, width, height));

  CefRefPtr<CefBrowser> browser = CefBrowserHost::CreateBrowserSync(
      window_info, handler, url_str, browser_settings, nullptr, nullptr);

  browser->AddRef();
  return browser.get();
}

void u_webview_delete(u_webview_t self) {
  CEF_REQUIRE_UI_THREAD();

  CefRefPtr<WebViewHandler> handler(WebViewHandler::GetInstance());
  CefBrowser *browser = static_cast<CefBrowser *>(self);

  handler->DoClose(browser);
  browser->Release();
}

void u_webview_open_dev_tools(u_webview_t self) {
  CEF_REQUIRE_UI_THREAD();

  CefBrowser *browser = static_cast<CefBrowser *>(self);

  CefBrowserSettings browser_settings;
  browser_settings.background_color = CefColorSetARGB(255, 255, 255, 0);

  CefWindowInfo window_info;

  browser->GetHost()->ShowDevTools(window_info, browser->GetHost()->GetClient(),
                                   browser_settings, CefPoint());
}

void u_webview_close_dev_tools(u_webview_t self) {
  CEF_REQUIRE_UI_THREAD();

  CefBrowser *browser = static_cast<CefBrowser *>(self);
  browser->GetHost()->CloseDevTools();
}
