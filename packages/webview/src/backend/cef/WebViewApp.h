#ifndef UNVRS_WEBVIEW_APP_H
#define UNVRS_WEBVIEW_APP_H

#include "include/cef_app.h"

// Implement application-level callbacks for the browser process.
class WebViewApp : public CefApp, public CefBrowserProcessHandler {
 public:
  WebViewApp();

  // CefApp methods:
  CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override {
    return this;
  }

  // CefBrowserProcessHandler methods:

  void OnBeforeCommandLineProcessing(
      const CefString& process_type,
      CefRefPtr<CefCommandLine> command_line) override;
  void OnContextInitialized() override;
  CefRefPtr<CefClient> GetDefaultClient() override;

 private:
  // Include the default reference counting implementation.
  IMPLEMENT_REFCOUNTING(WebViewApp);
};

#endif  // UNVRS_WEBVIEW_APP_H
