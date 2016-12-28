//
//  AppDelegate.m
//  ForceRest
//
//  Created by 小乖 on 16/12/28.
//  Copyright © 2016年 me.xiaoge. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

// @property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate


int state = 0;
int restSeconds = 0;

NSTimer* timer;


CGContextRef ctx;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(receiveSleep) name:NSWorkspaceWillSleepNotification object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(receiveWake) name:NSWorkspaceDidWakeNotification object:nil];
    
    [self startTimer];
    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void) receiveSleep {
    [timer invalidate];
}
- (void) receiveWake {
    [self startTimer];
}

- (void) startTimer {
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(receiveTimer) userInfo:nil repeats:YES];
}

- (void) receiveTimer {
    if (state == 1) {
        restSeconds--;
        if (restSeconds <= 0) {
            [self gotoWork];
        } else {
            [self updateRest:restSeconds];
        }
        return;
    }
    NSDate *date = [NSDate date];
    NSTimeZone *zone = [NSTimeZone systemTimeZone];
    NSInteger interval = [zone secondsFromGMTForDate: date];
    NSDate *localDate = [date  dateByAddingTimeInterval: interval];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:localDate];
    NSInteger minute = [components minute];
    NSLog(@"%ld", (long)minute);
    
    if (minute == 0) {
        restSeconds = 180;
        [self gotoRest];
        [self updateRest:restSeconds];
    } else if (minute == 15 || minute == 45) {
        restSeconds = 60;
        [self gotoRest];
        [self updateRest:restSeconds];
    } else if (minute == 30) {
        restSeconds = 120;
        [self gotoRest];
        [self updateRest:restSeconds];
    }
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
    state = 1;
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
    state = 0;
    CGReleaseAllDisplays();
}


@end
