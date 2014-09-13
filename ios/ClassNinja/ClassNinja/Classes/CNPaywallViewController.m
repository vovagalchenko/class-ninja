//
//  CNPaywallViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 9/13/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNPaywallViewController.h"

@interface CNPaywallViewController ()
@property (nonatomic) UIButton *cancel;
@property (nonatomic) UIButton *signUp;
@property (nonatomic) UILabel *marketingMessage;
@end

@implementation CNPaywallViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.cancel];
    [self.view addSubview:self.signUp];
    [self.view addSubview:self.marketingMessage];
}

- (UIButton *)cancel
{
    if (_cancel) {
        _cancel = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancel.titleLabel.text = @"Cancel";
    }
    return _cancel;
}

- (UIButton *)signUp
{
    if (_signUp) {
        _signUp = [UIButton buttonWithType:UIButtonTypeCustom];
        _signUp.titleLabel.text = @"Sure, sign me up";

    }
    return _signUp;
}

- (UILabel *)marketingMessage
{
    if (_marketingMessage) {
        _marketingMessage = [[UILabel alloc] init];
        
        NSString *message =@"The first 2 classes of the semester that you want to track are free.\n"
                            "For just 0.99$, you'll be able to track an unlimited number of classes for this semester";
        _marketingMessage.text = message;
    }
    return _marketingMessage;
}


@end
