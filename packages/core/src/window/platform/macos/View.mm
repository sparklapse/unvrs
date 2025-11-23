#include <window.h>

#include <AppKit/AppKit.h>

u_view_t u_view_create(double_t x, double_t y, double_t width, double_t height) {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(x, y, width, height)];

    return view;
}

void u_view_set_pos(u_view_t self, double_t x, double_t y) {
  NSView *view = static_cast<NSView *>(self);
  [view setFrameOrigin:NSMakePoint(x, y)];
}

void u_view_resize(u_view_t self, double_t width, double_t height) {
  NSView *view = static_cast<NSView *>(self);
  [view setFrameSize:NSMakeSize(width, height)];
}
