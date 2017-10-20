//
//  ViewController.m
//  TestForAsyncLayer
//
//  Created by 李应鹏 on 2017/10/9.
//  Copyright © 2017年 李应鹏. All rights reserved.
//

#import "ViewController.h"
#import "MyLabel.h"
#import "MyView.h"
#import "FitLabel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *str = @"Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫 Async Display Test ✺◟(∗❛ัᴗ❛ั∗)◞✺ ✺◟(∗❛ัᴗ❛ั∗)◞✺ 😀😖😐😣😡🚖🚌🚋🎊💖💗💛💙🏨🏦🏫";

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:str];
    [text addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:20] range:NSMakeRange(0, text.length)];
    [text addAttribute:NSStrokeColorAttributeName value:(id)[UIColor redColor].CGColor range:NSMakeRange(0, text.length)];
    
//    MyLabel *label = [MyLabel new];
//    label.frame = CGRectMake(0, 0, 200, 100);
//    label.center = self.view.center;
//    label.layer.backgroundColor = [UIColor greenColor].CGColor;
//    label.attributedText = text;
    
    FitLabel *label = [[FitLabel alloc] init];
    label.attributedText = text;
    CGSize size = [label intrinsicContentSize];
    label.frame = CGRectMake(0, 0, size.width, size.height);
    label.center = self.view.center;
    [self.view addSubview:label];
//    [self.view addSubview:view];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
