#include <webview.h>

#include "include/cef_v8.h"
#include "include/wrapper/cef_helpers.h"


void u_js_context_set_value_string(u_js_context_t self, uint8_t *k, size_t k_length, uint8_t *v, size_t v_length) {
  CEF_REQUIRE_RENDERER_THREAD();

  CefV8Context *context = static_cast<CefV8Context *>(self);
  std::string key(reinterpret_cast<char *>(k), k_length);
  std::string value(reinterpret_cast<char *>(v), v_length);
  CefRefPtr<CefV8Value> value_string = CefV8Value::CreateString(value);

  context->Enter();
  CefRefPtr<CefV8Value> global = context->GetGlobal();
  global->SetValue(key, value_string, V8_PROPERTY_ATTRIBUTE_READONLY);
  context->Exit();
}
