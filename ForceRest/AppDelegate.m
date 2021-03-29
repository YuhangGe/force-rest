#import "AppDelegate.h"

@interface AppDelegate ()

// @property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate


int state = 0;
int restSeconds = 0;
unsigned tickTs = 0;
int pwdIdx = 0;

/**
 密码 12345ssdlh
 需要注意 keycode 不是 ascii 码。
 参看：https://stackoverflow.com/questions/3202629/where-can-i-find-a-list-of-mac-virtual-key-codes/16125341
 */
int pwd[] = {0x12, 0x13, 0x14, 0x15, 0x17, 0x1, 0x1, 0x2, 0x25, 0x4};

bool appQuit = false;
CGContextRef ctx;

- (bool) poll {
  NSEvent *event = [NSApp nextEventMatchingMask:NSKeyDownMask
                      untilDate:[NSDate dateWithTimeIntervalSinceNow:0.1] inMode:NSDefaultRunLoopMode dequeue:YES];
    
  if (!event)
    return false;
  
  // NSLog(@"%@", event);
  if ([event type] != NSKeyDown) {
    [NSApp sendEvent:event];
    return false;
  }
  int kc = [event keyCode];
//  NSLog(@"%d, %d, %d", pwdIdx, kc, pwd[pwdIdx]);
  if (pwd[pwdIdx] == kc) {
    pwdIdx++;
  } else {
    pwdIdx = 0;
  }
  if (pwdIdx == 10) {
    if (state == 1) {
      [self gotoWork];
      state = 2;
    }
    pwdIdx = 0;
  }
  return true;
    
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  
  @autoreleasepool {
    while(appQuit == false) {
  
      if (state == 1) {
        while([self poll]) {}
      }
  
      if (state == 0) {
        NSDate *date = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
        NSInteger minute = [components minute];
        if (minute == 57) {
          restSeconds = 150;
        } else if (minute == 14 || minute == 44) {
          restSeconds = 90;
        } else if (minute == 28) {
          restSeconds = 120;
        }
        if (restSeconds > 0) {
          pwdIdx = 0;
          state = 1;
          [self gotoRest];
          [self updateRest:restSeconds];
        }
      } else if (state == 1 || state == 2) {
        restSeconds--;
//        NSLog(@"%d", restSeconds);
        if (state == 1) {
          [self updateRest:restSeconds];
        }
        if (restSeconds == 0) {
          if (state == 1) {
            [self gotoWork];
          }
          state = 0;
        }
      }

      sleep(1);
    }
  }
  
  
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
  NSLog(@"will quit");
  appQuit = true;
}

-(void) updateRest: (int) ti {
  int minutes = ti / 60;
  int seconds = ti - minutes * 60;
  NSString *sm = [NSString stringWithFormat:minutes >= 10 ? @"%d" : @"0%d", minutes];
  NSString *ss = [NSString stringWithFormat:seconds >= 10 ? @"%d" : @"0%d", seconds];
  NSString *st = [NSString stringWithFormat:@"%@:%@", sm, ss];
  
  CGContextClearRect(ctx, CGRectMake(0, 0, 300, 300));
  
  CTFontRef font = CTFontCreateWithName(CFSTR("Times"), 70, NULL);
  
  // Create an attributed string
  CFStringRef keys[] = { kCTFontAttributeName , kCTForegroundColorFromContextAttributeName};
  CFTypeRef values[] = { font, kCFBooleanTrue };
  CFDictionaryRef attr = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values,
                                            sizeof(keys) / sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
  
  CFStringRef tipStr = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%@"), st);
  CFAttributedStringRef attrString = CFAttributedStringCreate(NULL, tipStr, attr);
  CFRelease(attr);
  CFRelease(tipStr);
  
  // Draw the string
  CTLineRef line = CTLineCreateWithAttributedString(attrString);
  CGContextSetTextPosition(ctx, 20, 20);
  CTLineDraw(line, ctx);
  // Clean up
  CFRelease(line);
  CFRelease(attrString);
  CFRelease(font);
}
-(void) gotoRest {
  CGDirectDisplayID display = kCGDirectMainDisplay;
  CGError err = CGCaptureAllDisplays(); // CGDisplayCapture (display);
  
  if (err != kCGErrorSuccess) {
    return;
  }
  ctx = CGDisplayGetDrawingContext (display); // 3
  if (ctx == NULL) {
    return;
  }
  
  CGContextSetTextDrawingMode (ctx, kCGTextFill);
  CGContextSetRGBFillColor (ctx, 1, 0, 0, 1);
  CGContextSetRGBStrokeColor (ctx, 1, 0, 0, 1);
}
-(void) gotoWork {
  CGReleaseAllDisplays();
}


@end
