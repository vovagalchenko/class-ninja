//
//  ClassNinja
//
//  Created by Boris Suvorov on 8/9/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNCourseDetailsViewController.h"

#define kCloseButtonWidth  22
#define kCloseButtonHeight 22

#define kCloseButtonXOffset 20
#define kCloseButtonYOffset 15

@interface CNCourseDetailsViewController ()

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *closeButton;
@end

@implementation CNCourseDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.closeButton];
}

- (void)viewWillLayoutSubviews
{
    self.titleLabel.frame = self.view.bounds;
    self.closeButton.frame = CGRectMake(kCloseButtonXOffset, kCloseButtonYOffset,
                                        kCloseButtonWidth, kCloseButtonHeight);
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        //UPDATEME: just a placeholder frame/title/colors
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = self.course.name;
        _titleLabel.textColor = [UIColor purpleColor];
    }
    return _titleLabel;
}

- (UIButton *)closeButton
{
    if (_closeButton == nil) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (void)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
