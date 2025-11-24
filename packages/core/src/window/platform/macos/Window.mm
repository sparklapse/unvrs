#include <AppKit/AppKit.h>
#include <window.h>

#include "loop/platform/macos/App.h"
#include "window/platform/macos/Window.h"

@implementation UWindow
@end

@implementation UView
- (BOOL)isFlipped {
  return YES;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}
@end

u_window_t u_window_create(double_t x, double_t y, double_t width,
                           double_t height) {
  UApp *app = [UApp sharedApplication];

  // Position from top left as 0,0
  NSRect rect = NSMakeRect(
      x, NSScreen.mainScreen.frame.size.height - height - y, width, height);
  NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskResizable;
  UWindow *win = [[UWindow alloc] initWithContentRect:rect
                                            styleMask:style
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
  [win setTitle:@"unvrs window"];
  [win makeKeyAndOrderFront:app];
  [win setAcceptsMouseMovedEvents:YES];
  [win setTitlebarAppearsTransparent:YES];
  [win setCanHide:YES];

  NSView *root = [[UView alloc] init];
  [win setContentView:root];
  [win makeFirstResponder:root];

  return win;
}

void u_window_delete(u_window_t self) {
  UWindow *win = static_cast<UWindow *>(self);
  [win close];
  [win release];
}

bool u_window_is_visible(u_window_t self) {
  UWindow *win = static_cast<UWindow *>(self);
  return static_cast<bool>([win isVisible]);
}

void u_window_set_visible(u_window_t self, bool visible) {
  UWindow *win = static_cast<UWindow *>(self);
  [win setIsVisible:static_cast<BOOL>(visible)];
}

void u_window_set_background_color(u_window_t self, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
  UWindow *win = static_cast<UWindow *>(self);
  NSColor *bg = [NSColor colorWithSRGBRed:(CGFloat)r/255
                                    green:(CGFloat)g/255
                                     blue:(CGFloat)b/255
                                    alpha:(CGFloat)a/255];
  [win setBackgroundColor:bg];
}

u_view_t u_window_get_root_view(u_window_t self) {
  UWindow *win = static_cast<UWindow *>(self);
  NSView *root = win.contentView;

  return root;
}

void u_window_add_view(u_window_t self, u_view_t view_ptr) {
  UWindow *win = static_cast<UWindow *>(self);
  NSView *root = win.contentView;
  NSView *view = static_cast<NSView *>(view_ptr);

  [root addSubview:view];
}
