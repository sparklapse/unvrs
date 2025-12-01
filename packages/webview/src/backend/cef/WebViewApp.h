#ifndef UNVRS_WEBVIEW_APP_H
#define UNVRS_WEBVIEW_APP_H

#include "include/cef_app.h"
#include "include/cef_render_process_handler.h"

class WebViewApp : public CefApp,
                   public CefBrowserProcessHandler,
                   public CefRenderProcessHandler {
public:
  WebViewApp();

  bool OnProcessMessageReceived(CefRefPtr<CefBrowser> browser, CefRefPtr<CefFrame> frame, CefProcessId source_process, CefRefPtr<CefProcessMessage> message) override;

  CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override {
    return this;
  }

  void OnBeforeCommandLineProcessing(
      const CefString &process_type,
      CefRefPtr<CefCommandLine> command_line) override;
  void OnContextInitialized() override;
  CefRefPtr<CefClient> GetDefaultClient() override;

  CefRefPtr<CefRenderProcessHandler> GetRenderProcessHandler() override {
      return this;
  }
private:
  IMPLEMENT_REFCOUNTING(WebViewApp);
  DISALLOW_COPY_AND_ASSIGN(WebViewApp);
};

#endif // UNVRS_WEBVIEW_APP_H
