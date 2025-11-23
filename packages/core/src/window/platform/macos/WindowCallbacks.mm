#include <window.h>

#include "window/platform/macos/Window.h"

void u_window_callback_add_resize(void (*caller)(void *, void *,
                                                 WindowResizeParams),
                                  u_window_t self, void *callable,
                                  void *context) {
  UWindow *win = static_cast<UWindow *>(self);
  NSView *root = win.contentView;
  id observer = [[NSNotificationCenter defaultCenter]
      addObserverForName:NSViewFrameDidChangeNotification
                  object:root
                   queue:nil
              usingBlock:^(NSNotification *notification) {
                NSView *view = notification.object;
                WindowResizeParams params;
                params.width = view.frame.size.width;
                params.height = view.frame.size.height;
                caller(callable, context, params);
              }];
}

// void u_window_callbacks_add_mouse_move(u_window_t self, void *ctx,
//                                         void *callback) {
//   UWindow *win = static_cast<UWindow *>(self);
//   NSView *root = win.contentView;
//   NSEvent * (^handler)(NSEvent *) = ^NSEvent *(NSEvent *event) {
//     if (event.window == win) {
//       NSPoint pos = [root convertPoint:[event locationInWindow]
//       fromView:nil]; u_window_callbacks_run_mouse_move(ctx, callback, pos.x,
//       pos.y);
//     }
//     return event;
//   };
//
//   id monitor =
//       [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskMouseMoved
//                                             handler:handler];
// }
