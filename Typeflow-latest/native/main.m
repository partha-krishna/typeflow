#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>

@interface TypeflowApp : NSObject <NSApplicationDelegate>
@property(nonatomic) NSStatusItem *statusItem;
@property(nonatomic) CFMachPortRef tap;
@property(nonatomic) NSPanel *panel;
@property(nonatomic) NSString *word;
@property(nonatomic) NSString *previousWord;
@property(nonatomic) NSString *candidate;
@property(nonatomic) NSArray<NSString *> *suggestions;
@property(nonatomic) NSUInteger selectedSuggestion;
@property(nonatomic) NSDictionary *currentContext;
@property(nonatomic) BOOL injecting;
@property(nonatomic) BOOL dismissed;
@property(nonatomic) BOOL enabled;
@property(nonatomic) BOOL listenerActive;
@property(nonatomic) BOOL listenAccess;
@property(nonatomic) BOOL postAccess;
@property(nonatomic) BOOL accessibilityAccess;
@property(nonatomic) NSUInteger refreshGeneration;
@end

static CGEventRef TypeflowEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *info);

@implementation TypeflowApp
- (void)applicationDidFinishLaunching:(NSNotification *)note {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    self.word = @""; self.previousWord = @""; self.candidate = @""; self.enabled = YES;
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"t."; self.statusItem.button.toolTip = @"Typeflow — system-wide word completion";
    [self requestPermissionsAndStart];
}
- (void)buildMenu {
    NSMenu *menu = [NSMenu new];
    NSString *state = self.listenerActive ? @"Keyboard listener active" : @"Keyboard listener blocked";
    NSMenuItem *title = [[NSMenuItem alloc] initWithTitle:state action:nil keyEquivalent:@""]; title.enabled = NO; [menu addItem:title];
    NSMenuItem *listen = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Input Monitoring: %@", self.listenAccess ? @"Granted" : @"Permission needed"] action:nil keyEquivalent:@""]; listen.enabled = NO; [menu addItem:listen];
    NSMenuItem *accessibility = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Accessibility: %@", self.accessibilityAccess ? @"Granted" : @"Permission needed"] action:nil keyEquivalent:@""]; accessibility.enabled = NO; [menu addItem:accessibility];
    NSMenuItem *posting = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Text insertion: %@", self.postAccess ? @"Granted" : @"Permission needed"] action:nil keyEquivalent:@""]; posting.enabled = NO; [menu addItem:posting];
    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *retry = [[NSMenuItem alloc] initWithTitle:@"Request / Retry Keyboard Access…" action:@selector(requestPermissionsAndStart) keyEquivalent:@""]; retry.target = self; [menu addItem:retry];
    NSMenuItem *accessibilitySettings = [[NSMenuItem alloc] initWithTitle:@"Open Accessibility Settings" action:@selector(openAccessibilitySettings) keyEquivalent:@""]; accessibilitySettings.target = self; [menu addItem:accessibilitySettings];
    NSMenuItem *inputSettings = [[NSMenuItem alloc] initWithTitle:@"Open Input Monitoring Settings" action:@selector(openPermissions) keyEquivalent:@""]; inputSettings.target = self; [menu addItem:inputSettings];
    [menu addItem:NSMenuItem.separatorItem];
    NSMenuItem *toggle = [[NSMenuItem alloc] initWithTitle:(self.enabled ? @"Pause suggestions" : @"Resume suggestions") action:@selector(toggle) keyEquivalent:@"p"]; toggle.target = self; [menu addItem:toggle];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"Quit Typeflow" action:@selector(quit) keyEquivalent:@"q"]; quit.target = self; [menu addItem:quit];
    self.statusItem.menu = menu;
}
- (void)requestPermissionsAndStart {
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    self.accessibilityAccess = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    self.listenAccess = CGPreflightListenEventAccess();
    if (!self.listenAccess) self.listenAccess = CGRequestListenEventAccess();
    self.postAccess = CGPreflightPostEventAccess();
    if (!self.postAccess) self.postAccess = CGRequestPostEventAccess();
    if (!self.tap) [self startTap];
    [self buildMenu];
}
- (void)startTap {
    CGEventMask mask = CGEventMaskBit(kCGEventKeyDown);
    self.tap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, mask, TypeflowEvent, (__bridge void *)self);
    if (!self.tap) {
        self.listenerActive = NO; [self buildMenu]; return;
    }
    self.listenerActive = YES; [self buildMenu];
    CFRunLoopSourceRef source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, self.tap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes); CFRelease(source);
    CGEventTapEnable(self.tap, true);
}
- (void)handleEvent:(CGEventRef)event {
    if (!self.enabled || self.injecting) return;
    if ([self isFocusedFieldSecure]) { self.word = @""; self.candidate = @""; self.suggestions = @[]; self.dismissed = NO; dispatch_async(dispatch_get_main_queue(), ^{ [self hidePanel]; }); return; }
    CGEventFlags flags = CGEventGetFlags(event);
    if (flags & (kCGEventFlagMaskCommand | kCGEventFlagMaskControl | kCGEventFlagMaskAlternate)) return;
    CGKeyCode code = (CGKeyCode)CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode);
    UniChar chars[8] = {0}; UniCharCount length = 0; CGEventKeyboardGetUnicodeString(event, 8, &length, chars);
    NSString *typed = [[NSString alloc] initWithCharacters:chars length:length];

    if ((code == 51 || code == 117) && self.suggestions.count && !self.dismissed) {
        self.dismissed = YES; dispatch_async(dispatch_get_main_queue(), ^{ [self hidePanel]; }); CGEventSetType(event, kCGEventNull); return;
    }
    if (code == 53 && self.suggestions.count && !self.dismissed) {
        self.dismissed = YES; dispatch_async(dispatch_get_main_queue(), ^{ [self hidePanel]; }); CGEventSetType(event, kCGEventNull); return;
    }
    if (code == 125 || code == 126) {
        if (self.suggestions.count && !self.dismissed) { NSInteger delta = code == 125 ? 1 : -1; NSInteger count = (NSInteger)self.suggestions.count; self.selectedSuggestion = (NSUInteger)((((NSInteger)self.selectedSuggestion + delta) % count + count) % count); dispatch_async(dispatch_get_main_queue(), ^{ [self showSuggestion]; }); CGEventSetType(event, kCGEventNull); return; }
        [self scheduleContextRefresh]; return;
    }

    BOOL acceptKey = code == 49 || code == 48 || code == 36 || code == 76;
    if (acceptKey) {
        [self updateCandidate];
        if (self.suggestions.count && !self.dismissed && self.currentContext && [self replaceCurrentWordWithCandidate:self.suggestions[self.selectedSuggestion]]) {
            CGEventSetType(event, kCGEventNull); return;
        }
        if (code == 49 || code == 48 || code == 36 || code == 76) { self.previousWord = self.word.lowercaseString; self.word = @""; self.suggestions = @[]; self.candidate = @""; self.dismissed = NO; dispatch_async(dispatch_get_main_queue(), ^{ [self hidePanel]; }); }
        return;
    }

    NSCharacterSet *letters = [NSCharacterSet letterCharacterSet]; BOOL valid = typed.length > 0;
    for (NSUInteger i = 0; i < typed.length; i++) { unichar c = [typed characterAtIndex:i]; if (![letters characterIsMember:c] && c != '\'' && c != 0x2019 && c != '-') { valid = NO; break; } }
    if (valid) { self.word = [self.word stringByAppendingString:typed.lowercaseString]; self.dismissed = NO; [self scheduleContextRefresh]; }
    else if (code == 51 && self.word.length) { self.word = [self.word substringToIndex:self.word.length - 1]; [self scheduleContextRefresh]; }
    else if (code == 117 || code == 51 || code == 123 || code == 124 || code == 115 || code == 119 || code == 116 || code == 121 || typed.length) {
        self.dismissed = NO; [self scheduleContextRefresh];
    }
}
- (BOOL)isFocusedFieldSecure {
    pid_t pid = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
    AXUIElementRef app = AXUIElementCreateApplication(pid); CFTypeRef focused = NULL;
    if (AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute, &focused) != kAXErrorSuccess) { CFRelease(app); return NO; }
    CFTypeRef subrole = NULL; BOOL secure = NO;
    if (AXUIElementCopyAttributeValue((AXUIElementRef)focused, kAXSubroleAttribute, &subrole) == kAXErrorSuccess) { NSString *s = CFBridgingRelease(subrole); secure = [s.lowercaseString containsString:@"secure"]; }
    CFRelease(focused); CFRelease(app); return secure;
}
- (void)scheduleContextRefresh {
    NSUInteger generation = ++self.refreshGeneration;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.035 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ if (generation == self.refreshGeneration) [self updateCandidate]; });
}
- (BOOL)isWordCharacter:(unichar)c {
    return [[NSCharacterSet alphanumericCharacterSet] characterIsMember:c] || c == '\'' || c == 0x2019 || c == '-';
}
- (NSDictionary *)readCurrentTextContext {
    pid_t pid = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
    AXUIElementRef app = AXUIElementCreateApplication(pid); CFTypeRef focused = NULL;
    if (AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute, &focused) != kAXErrorSuccess) { CFRelease(app); return nil; }
    AXUIElementRef element = (AXUIElementRef)focused; CFTypeRef subrole = NULL;
    if (AXUIElementCopyAttributeValue(element, kAXSubroleAttribute, &subrole) == kAXErrorSuccess) {
        NSString *role = CFBridgingRelease(subrole);
        if ([role.lowercaseString containsString:@"secure"]) { CFRelease(focused); CFRelease(app); return nil; }
    }
    CFTypeRef rawText = NULL, rawRange = NULL;
    BOOL hasText = AXUIElementCopyAttributeValue(element, kAXValueAttribute, &rawText) == kAXErrorSuccess;
    BOOL hasRange = AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute, &rawRange) == kAXErrorSuccess;
    if (!hasText || !hasRange || !rawText || !rawRange) { if (rawText) CFRelease(rawText); if (rawRange) CFRelease(rawRange); CFRelease(focused); CFRelease(app); return nil; }
    NSString *text = (__bridge NSString *)rawText; CFRange cfRange;
    if (![text isKindOfClass:NSString.class] || !AXValueGetValue((AXValueRef)rawRange, kAXValueTypeCFRange, &cfRange) || cfRange.location < 0 || cfRange.length != 0 || (NSUInteger)cfRange.location > text.length) {
        CFRelease(rawText); CFRelease(rawRange); CFRelease(focused); CFRelease(app); return nil;
    }
    NSUInteger caret = (NSUInteger)cfRange.location, start = caret, end = caret;
    while (start > 0 && [self isWordCharacter:[text characterAtIndex:start - 1]]) start--;
    while (end < text.length && [self isWordCharacter:[text characterAtIndex:end]]) end++;
    if (start == end || start == caret) { CFRelease(rawText); CFRelease(rawRange); CFRelease(focused); CFRelease(app); return nil; }
    NSRange wordRange = NSMakeRange(start, end - start);
    NSString *word = [[text substringWithRange:wordRange] lowercaseString];
    NSString *before = [[text substringToIndex:start] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *previous = @"";
    if (before.length) {
        NSUInteger p = before.length;
        while (p > 0 && [self isWordCharacter:[before characterAtIndex:p - 1]]) p--;
        previous = [[before substringFromIndex:p] lowercaseString];
    }
    id elementObject = CFBridgingRelease(focused);
    NSDictionary *context = @{ @"pid": @(pid), @"element": elementObject, @"text": text, @"range": [NSValue valueWithRange:wordRange], @"word": word, @"actualWord": [text substringWithRange:wordRange], @"previous": previous, @"caret": @(caret) };
    CFRelease(rawText); CFRelease(rawRange); CFRelease(app);
    return context;
}
- (NSArray<NSString *> *)candidatesForContext:(NSDictionary *)context {
    NSString *word = context[@"word"] ?: self.word.lowercaseString;
    if (word.length == 0) return @[];
    NSArray *fallback = @[@"the",@"and",@"you",@"your",@"that",@"this",@"with",@"for",@"from",@"have",@"will",@"can",@"would",@"could",@"should",@"because",@"when",@"what",@"where",@"which",@"quick",@"brown",@"fox",@"thought",@"idea",@"meeting",@"project",@"today",@"tomorrow",@"important",@"really",@"write",@"typing",@"suggestion",@"sentence",@"finally",@"final",@"finish",@"find",@"fine",@"word",@"words",@"help",@"make",@"more",@"less",@"than",@"then",@"there",@"their",@"they",@"we",@"are",@"was",@"is",@"it",@"in",@"on",@"to",@"of",@"a",@"an",@"my",@"our",@"about",@"just",@"like",@"know",@"think",@"feel",@"want",@"need",@"please",@"thanks",@"hello",@"great",@"good",@"also",@"not",@"but",@"if",@"as",@"at",@"by",@"be",@"do",@"done",@"go",@"get",@"see",@"look",@"use",@"time",@"work",@"fast",@"faster",@"note",@"draft",@"simple",@"easy",@"best",@"new",@"morning",@"forward",@"am",@"because",@"people",@"going",@"something",@"different",@"following",@"important",@"interested",@"information",@"appointment",@"available",@"conversation",@"tomorrow"];
    NSDictionary *preferred = @{@"the":@[@"quick",@"best",@"new",@"idea",@"project"],@"quick":@[@"brown"],@"brown":@[@"fox"],@"i":@[@"think",@"want",@"need",@"would",@"can",@"have",@"am"],@"thank":@[@"you"],@"looking":@[@"forward"],@"see":@[@"you"],@"what":@[@"do",@"would",@"is"],@"how":@[@"are",@"do",@"to"],@"in":@[@"the"],@"on":@[@"the"],@"for":@[@"the"],@"would":@[@"like"],@"can":@[@"you"],@"we":@[@"can",@"should",@"will"],@"let":@[@"me"],@"good":@[@"morning",@"idea"],@"please":@[@"let",@"send",@"see"],@"tomorrow":@[@"morning"]};
    NSMutableArray<NSString *> *results = [NSMutableArray new]; NSMutableSet<NSString *> *seen = [NSMutableSet new];
    void (^add)(NSString *) = ^(NSString *candidate) { if (candidate.length > word.length && [candidate.lowercaseString hasPrefix:word] && ![seen containsObject:candidate.lowercaseString]) { [results addObject:candidate]; [seen addObject:candidate.lowercaseString]; } };
    for (NSString *item in preferred[context[@"previous"] ?: self.previousWord] ?: @[]) add(item);
    if (context) {
        NSValue *value = context[@"range"]; NSString *text = context[@"text"];
        NSArray *system = [[NSSpellChecker sharedSpellChecker] completionsForPartialWordRange:value.rangeValue inString:text language:@"en_US" inSpellDocumentWithTag:0];
        for (NSString *item in system ?: @[]) add(item);
    }
    for (NSString *item in fallback) add(item);
    if (results.count > 4) [results removeObjectsInRange:NSMakeRange(4, results.count - 4)];
    return results;
}
- (void)updateCandidate {
    NSUInteger previousSelection = self.selectedSuggestion;
    NSString *previousTypedWord = self.word.lowercaseString;
    self.currentContext = [self readCurrentTextContext];
    if (self.currentContext) { self.word = self.currentContext[@"word"]; self.previousWord = self.currentContext[@"previous"]; }
    self.suggestions = [self candidatesForContext:self.currentContext];
    self.selectedSuggestion = ([previousTypedWord isEqualToString:self.word.lowercaseString] && previousSelection < self.suggestions.count) ? previousSelection : 0;
    self.candidate = self.suggestions.firstObject ?: @""; self.dismissed = NO;
    if (!self.candidate.length) { dispatch_async(dispatch_get_main_queue(), ^{ [self hidePanel]; }); return; }
    dispatch_async(dispatch_get_main_queue(), ^{ [self showSuggestion]; });
}
- (BOOL)replaceCurrentWordWithCandidate:(NSString *)candidate {
    NSDictionary *context = self.currentContext;
    if (!context) return NO;
    AXUIElementRef element = (__bridge AXUIElementRef)context[@"element"];
    NSRange range = [context[@"range"] rangeValue]; CFRange cfRange = CFRangeMake((CFIndex)range.location, (CFIndex)range.length);
    AXValueRef selected = AXValueCreate(kAXValueTypeCFRange, &cfRange);
    AXError error = AXUIElementSetAttributeValue(element, kAXSelectedTextRangeAttribute, selected); CFRelease(selected);
    if (error != kAXErrorSuccess) return NO;
    NSString *replacement = candidate;
    NSString *original = context[@"actualWord"] ?: context[@"word"];
    if (original.length && [[original substringToIndex:1] isEqualToString:[[original substringToIndex:1] uppercaseString]]) replacement = candidate.capitalizedString;
    self.injecting = YES;
    pid_t pid = [context[@"pid"] intValue];
    dispatch_async(dispatch_get_main_queue(), ^{ [self hidePanel]; [self postText:[replacement stringByAppendingString:@" "] toPID:pid]; self.injecting = NO; });
    self.previousWord = candidate.lowercaseString; self.word = @""; self.suggestions = @[]; self.candidate = @""; self.dismissed = NO;
    return YES;
}
- (CGRect)wordBounds {
    if (!self.currentContext) return CGRectNull;
    AXUIElementRef element = (__bridge AXUIElementRef)self.currentContext[@"element"];
    NSRange range = [self.currentContext[@"range"] rangeValue]; CFRange cfRange = CFRangeMake((CFIndex)range.location, (CFIndex)range.length);
    AXValueRef axRange = AXValueCreate(kAXValueTypeCFRange, &cfRange); CFTypeRef bounds = NULL; CGRect rect = CGRectNull;
    if (AXUIElementCopyParameterizedAttributeValue(element, kAXBoundsForRangeParameterizedAttribute, axRange, &bounds) == kAXErrorSuccess && bounds) { AXValueGetValue((AXValueRef)bounds, kAXValueTypeCGRect, &rect); CFRelease(bounds); }
    CFRelease(axRange); return rect;
}
- (void)showSuggestion {
    if (!self.suggestions.count || self.dismissed) { [self hidePanel]; return; }
    NSUInteger visibleCount = MIN((NSUInteger)3, self.suggestions.count);
    CGFloat width = 190, rowHeight = 25, height = rowHeight * visibleCount + 8;
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, height)]; view.wantsLayer = YES; view.layer.cornerRadius = 7; view.layer.backgroundColor = [NSColor colorWithWhite:.035 alpha:.98].CGColor; view.layer.borderWidth = 1; view.layer.borderColor = [NSColor colorWithWhite:.24 alpha:1].CGColor;
    for (NSUInteger i = 0; i < visibleCount; i++) {
        CGFloat y = height - 4 - rowHeight * (i + 1);
        NSView *row = [[NSView alloc] initWithFrame:NSMakeRect(4, y, width - 8, rowHeight)]; row.wantsLayer = YES; row.layer.cornerRadius = 4;
        if (i == self.selectedSuggestion) row.layer.backgroundColor = [NSColor colorWithWhite:.19 alpha:1].CGColor;
        NSTextField *label = [NSTextField labelWithString:self.suggestions[i]]; label.font = [NSFont systemFontOfSize:12 weight:(i == self.selectedSuggestion ? NSFontWeightSemibold : NSFontWeightRegular)]; label.textColor = NSColor.whiteColor; label.frame = NSMakeRect(9, 4, width - 68, 16); [row addSubview:label];
        if (i == 0) { NSTextField *shortcut = [NSTextField labelWithString:@"Space"] ; shortcut.font = [NSFont systemFontOfSize:10]; shortcut.textColor = [NSColor colorWithWhite:.68 alpha:1]; shortcut.alignment = NSTextAlignmentRight; shortcut.frame = NSMakeRect(width - 60, 5, 48, 14); [row addSubview:shortcut]; }
        [view addSubview:row];
    }
    if (!self.panel) { self.panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, width, height) styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel backing:NSBackingStoreBuffered defer:NO]; self.panel.level = NSPopUpMenuWindowLevel; self.panel.backgroundColor = [NSColor colorWithWhite:.035 alpha:.98]; self.panel.opaque = NO; self.panel.hasShadow = YES; self.panel.ignoresMouseEvents = YES; self.panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary; }
    self.panel.contentView = view; [self.panel setContentSize:NSMakeSize(width, height)];
    CGRect word = [self wordBounds]; NSPoint origin;
    NSScreen *screen = NSScreen.mainScreen;
    if (CGRectIsNull(word)) { NSPoint mouse = NSEvent.mouseLocation; origin = NSMakePoint(mouse.x, mouse.y - height - 6); }
    else {
        // AX ranges use Quartz top-left screen coordinates. Convert through the
        // screen containing the text so the popup stays attached on multi-display setups.
        CGFloat bestDistance = CGFLOAT_MAX;
        for (NSScreen *candidateScreen in NSScreen.screens) {
            NSRect frame = candidateScreen.frame;
            CGFloat top = NSScreen.mainScreen.frame.size.height - CGRectGetMaxY(word);
            NSRect candidateRect = NSMakeRect(CGRectGetMinX(word), top, MAX(CGRectGetWidth(word), 1), MAX(CGRectGetHeight(word), 1));
            CGFloat distance = fabs(NSMidX(candidateRect) - NSMidX(frame)) + fabs(NSMidY(candidateRect) - NSMidY(frame));
            if (distance < bestDistance) { bestDistance = distance; screen = candidateScreen; }
        }
        CGFloat top = NSScreen.mainScreen.frame.size.height - CGRectGetMaxY(word);
        origin = NSMakePoint(CGRectGetMinX(word), top - height - 3);
    }
    NSRect visible = screen.visibleFrame; origin.x = MIN(MAX(origin.x, NSMinX(visible) + 4), NSMaxX(visible) - width - 4); origin.y = MIN(MAX(origin.y, NSMinY(visible) + 4), NSMaxY(visible) - height - 4);
    [self.panel setFrameOrigin:origin]; [self.panel orderFrontRegardless];
}
- (void)hidePanel { [self.panel orderOut:nil]; }
- (void)postText:(NSString *)text toPID:(pid_t)pid {
    for (NSUInteger i = 0; i < text.length; i++) { UniChar unit = [text characterAtIndex:i]; CGEventRef down = CGEventCreateKeyboardEvent(NULL, 0, true), up = CGEventCreateKeyboardEvent(NULL, 0, false); CGEventKeyboardSetUnicodeString(down, 1, &unit); CGEventKeyboardSetUnicodeString(up, 1, &unit); CGEventSetIntegerValueField(down, kCGEventSourceUserData, 0x54595045); CGEventSetIntegerValueField(up, kCGEventSourceUserData, 0x54595045); CGEventPostToPid(pid, down); CGEventPostToPid(pid, up); CFRelease(down); CFRelease(up); }
}
- (void)toggle { self.enabled = !self.enabled; if (!self.enabled) [self hidePanel]; [self buildMenu]; }
- (void)openPermissions { [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"]]; }
- (void)openAccessibilitySettings { [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"]]; }
- (void)quit { [NSApp terminate:nil]; }
@end

static CGEventRef TypeflowEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *info) {
    TypeflowApp *app = (__bridge TypeflowApp *)info;
    if (CGEventGetIntegerValueField(event, kCGEventSourceUserData) == 0x54595045) return event;
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) { if (app.tap) CGEventTapEnable(app.tap, true); return event; }
    if (type == kCGEventKeyDown) [app handleEvent:event];
    return CGEventGetType(event) == kCGEventNull ? NULL : event;
}

int main(int argc, const char *argv[]) {
    @autoreleasepool { NSApplication *app = NSApplication.sharedApplication; TypeflowApp *delegate = [TypeflowApp new]; app.delegate = delegate; [app run]; }
    return 0;
}
