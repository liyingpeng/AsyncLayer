//
//  MyLabel.m
//  TestForAsyncLayer
//
//  Created by 李应鹏 on 2017/10/9.
//  Copyright © 2017年 李应鹏. All rights reserved.
//

#import "MyLabel.h"
#import "YYAsyncLayer.h"
#import <CoreText/CoreText.h>

@interface MyLabel () <YYAsyncLayerDelegate>

@end

@implementation MyLabel

- (void)setText:(NSString *)text {
    [super setText:text];
    [self.layer setNeedsDisplay];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    self.layer.contents = nil;
    [super setAttributedText:attributedText];
    [self.layer setNeedsDisplay];
    [self invalidateIntrinsicContentSize];
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    [self.layer setNeedsDisplay];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.layer setNeedsDisplay];
}

+ (Class)layerClass {
    return YYAsyncLayer.class;
}

- (YYAsyncLayerDisplayTask *)newAsyncDisplayTask {
    NSString *text = self.text;
    UIFont *font = self.font;
    
    YYAsyncLayerDisplayTask *task = [YYAsyncLayerDisplayTask new];
//    task.willDisplay = ^(CALayer *layer) {
//        //...
//    };
//
    task.display = ^(CGContextRef context, CGSize size, BOOL(^isCancelled)(void)) {
        if (isCancelled()) return;
        [self.layer drawInContext:context];
//        NSArray *lines = CreateCTLines(text, font, size.width);
//        if (isCancelled()) return;
//
//        for (int i = 0; i < lines.count; i++) {
//            CTLineRef line = line[i];
//            CGContextSetTextPosition(context, 0, i * font.pointSize * 1.5);
//            CTLineDraw(line, context);
//            if (isCancelled()) return;
//        }
    };
//
//    task.didDisplay = ^(CALayer *layer, BOOL finished) {
//        if (finished) {
//            // finished
//        } else {
//            // cancelled
//        }
//    };
    
    return task;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
