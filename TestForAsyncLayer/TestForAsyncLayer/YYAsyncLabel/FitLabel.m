//
//  FitLabel.m
//  TestForAsyncLayer
//
//  Created by 李应鹏 on 2017/10/20.
//  Copyright © 2017年 李应鹏. All rights reserved.
//

#import "FitLabel.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <libkern/OSAtomic.h>

#define FitLabelLog(...) do { \
NSString *message = [NSString stringWithFormat:@"Test for fitlabel %@", ##__VA_ARGS__]; \
NSLog(@"%@", message); \
} while (0)

static dispatch_queue_t AsyncLayerGetDisplayQueue() {
#define MAX_QUEUE_COUNT 16
    static int queueCount;
    static dispatch_queue_t queues[MAX_QUEUE_COUNT];
    static dispatch_once_t onceToken;
    static int32_t counter = 0;
    dispatch_once(&onceToken, ^{
        queueCount = (int)[NSProcessInfo processInfo].activeProcessorCount;
        queueCount = queueCount < 1 ? 1 : queueCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueCount;
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            for (NSUInteger i = 0; i < queueCount; i++) {
                dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
                queues[i] = dispatch_queue_create("com.ibireme.GCkit.render", attr);
            }
        } else {
            for (NSUInteger i = 0; i < queueCount; i++) {
                queues[i] = dispatch_queue_create("com.ibireme.GCkit.render", DISPATCH_QUEUE_SERIAL);
                dispatch_set_target_queue(queues[i], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
            }
        }
    });
    int32_t cur = OSAtomicIncrement32(&counter);
    if (cur < 0) cur = -cur;
    return queues[(cur) % queueCount];
#undef MAX_QUEUE_COUNT
}

static dispatch_queue_t AsyncLayerGetReleaseQueue() {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}

@interface FitLabel ()

@property(nonatomic, strong) NSLayoutManager *layoutManager;
@property(nonatomic, strong) NSTextContainer *textContainer;
@property(nonatomic, strong) NSTextStorage *textStorage;
@property(nonatomic) BOOL drawsAsync;

@property(nonatomic) CGFloat lineFragmentPadding;

@end

@implementation FitLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.layoutManager = [NSLayoutManager new];
        self.textContainer = [NSTextContainer new];
        self.textStorage = [NSTextStorage new];
        self.drawsAsync = YES;
        [self.layoutManager addTextContainer:self.textContainer];
        [self.textStorage addLayoutManager:self.layoutManager];
        self.layer.drawsAsynchronously = YES;
        self.numberOfLines = 0;
        self.preferredMaxLayoutWidth = CGFLOAT_MAX;
    }
    return self;
}

+ (Class)layerClass {
    return CALayer.class;
}

- (void)setPreferredMaxLayoutWidth:(CGFloat)preferredMaxLayoutWidth {
    [super setPreferredMaxLayoutWidth:preferredMaxLayoutWidth];
    [self updateContainer];
    FitLabelLog(@"setPreferredMaxLayoutWidth");
}

- (void)setNumberOfLines:(NSInteger)numberOfLines {
    [super setNumberOfLines:numberOfLines];
    [self updateContainer];
    FitLabelLog(@"setNumberOfLines");
}

- (void)updateContainer {
    FitLabelLog(@"updateContainer");
    self.textContainer.maximumNumberOfLines = self.numberOfLines;
    if (self.numberOfLines == 1) {
        self.textContainer.size = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    } else {
        self.textContainer.size = CGSizeMake(self.preferredMaxLayoutWidth, CGFLOAT_MAX);
    }
}

- (CGFloat)lineFragmentPadding {
    return self.textContainer.lineFragmentPadding;
}

- (void)setLineFragmentPadding:(CGFloat)lineFragmentPadding {
    self.textContainer.lineFragmentPadding = lineFragmentPadding;
}

- (void)invalidateTextContainer {
    FitLabelLog(@"invalidateTextContainer");
    [self.textStorage beginEditing];
    [self.textStorage setAttributedString:self.attributedText];
    [self.textStorage endEditing];
}

- (CGSize)intrinsicContentSize {
    FitLabelLog(@"intrinsicContentSize");
    CGSize size = [self.layoutManager usedRectForTextContainer:self.textContainer].size;
    if (size.width > self.preferredMaxLayoutWidth) {
        size.height = self.preferredMaxLayoutWidth / size.width * size.height;
        size.width = self.preferredMaxLayoutWidth;
    }
    return size;
}

- (CGSize)sizeThatFits:(CGSize)size {
    FitLabelLog(@"sizeThatFits");
    return self.intrinsicContentSize;
}

- (void)sizeToFit {
    FitLabelLog(@"sizeToFit");
    CGRect frame = self.frame;
    frame.size = self.intrinsicContentSize;
    self.frame = frame;
}

- (void)setFont:(UIFont *)font {
    FitLabelLog(@"setFont");
    [super setFont:font];
    [self invalidateTextContainer];
}

- (void)setTextColor:(UIColor *)textColor {
    FitLabelLog(@"setTextColor");
    [super setTextColor:textColor];
    [self invalidateTextContainer];
}

- (void)setText:(NSString *)text {
    FitLabelLog(@"setText");
    [super setText:text];
    [self invalidateTextContainer];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    FitLabelLog(@"setAttributedText");
    [super setAttributedText:attributedText];
    [self invalidateTextContainer];
}

- (void)drawTextInContext:(CGContextRef)ctx {
    FitLabelLog(@"drawTextInRect");
    CGRect rect = self.layer.bounds;
    if (self.backgroundColor) {
        [self.backgroundColor setFill];
        UIRectFill(rect);
    }
    CGRect textRect = [self.layoutManager usedRectForTextContainer:self.textContainer];
    float zoom = AVMakeRectWithAspectRatioInsideRect(textRect.size, self.bounds).size.width / textRect.size.width;
    CGContextScaleCTM(ctx, zoom, zoom);
    [self.layoutManager drawGlyphsForGlyphRange:NSMakeRange(0, self.textStorage.length) atPoint:CGPointMake((rect.size.width / zoom - textRect.size.width) / 2.0 - textRect.origin.x, (rect.size.height / zoom - textRect.size.height) / 2.0)];
}

- (void)displayLayer:(CALayer *)layer {
    FitLabelLog(@"displayLayer");
    if (!self.drawsAsync) {
        CGSize size = self.layer.bounds.size;
        BOOL opaque = self.layer.opaque;
        CGFloat scale = self.layer.contentsScale;
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [self drawTextInContext:context];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        self.layer.contents = (__bridge id)(image.CGImage);
        UIGraphicsEndImageContext();
    } else {
        CGSize size = self.layer.bounds.size;
        BOOL opaque = self.layer.opaque;
        CGFloat scale = self.layer.contentsScale;
        dispatch_async(AsyncLayerGetDisplayQueue(), ^{
            UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
            CGContextRef context = UIGraphicsGetCurrentContext();
            [self drawTextInContext:context];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            dispatch_async(dispatch_get_main_queue(), ^{
                self.layer.contents = (__bridge id)(image.CGImage);
            });
            UIGraphicsEndImageContext();
        });
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
