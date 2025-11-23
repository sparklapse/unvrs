#include <loop.h>

#include <AppKit/AppKit.h>

#include "loop/platform/macos/App.h"

@implementation UApp
- (void)configure {
  [[NSNotificationCenter defaultCenter]
      postNotificationName:NSApplicationWillFinishLaunchingNotification
                    object:NSApp];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:NSApplicationDidFinishLaunchingNotification
                    object:NSApp];

  // Make independent
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  [NSApp activateIgnoringOtherApps:YES];

  // Make main menu
  NSMenu *mainMenu = [[NSMenu alloc] init];
  NSMenuItem *mItem = [[NSMenuItem alloc] init];
  [mainMenu addItem:mItem];

  NSMenu *appMenu = [[NSMenu alloc] init];
  [mItem setSubmenu:appMenu];
  // Add Quit item (which also adds the shortcut to quit)
  NSMenuItem *quitItem = [[NSMenuItem alloc]
      initWithTitle:@"Quit unvrs" // TODO: get name from config
             action:@selector(stop:)
      keyEquivalent:@"q"];
  [appMenu addItem:quitItem];

  [NSApp setMainMenu:mainMenu];
}

- (void)start {
  [self run];
}

- (void)stop:(id)sender {
  [super stop:sender];
}
@end

u_app_t u_app_create() {
  NSApplication *app = [UApp sharedApplication];

  return static_cast<u_app_t>(app);
}

void u_app_delete(u_app_t self) {
  NSApplication *app = [UApp sharedApplication];
}

void u_app_run(u_app_t self) {
  UApp *app = [UApp sharedApplication];
  if (!app)
    return;

  [app configure];
  [app start];
}
