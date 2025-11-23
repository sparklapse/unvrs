#include "WebViewApp.h"

void WebViewApp::OnBeforeCommandLineProcessing(
    const CefString &process_type, CefRefPtr<CefCommandLine> command_line) {
  command_line->AppendSwitch("use-mock-keychain");
}
