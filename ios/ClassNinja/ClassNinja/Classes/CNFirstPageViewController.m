//
//  CNFirstPageViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 11/15/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNFirstPageViewController.h"

@interface CNSiongsTernaryViewController ()
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *descriptionLabel;
@property (nonatomic) UIButton *button;


@property (nonatomic) NSLayoutFormatOptions layoutOptions;
@end

@implementation CNSiongsTernaryViewController

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _layoutOptions = NSLayoutFormatAlignAllRight;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.descriptionLabel];
    [self.view addSubview:self.button];
    [self setupConstraints];
}

- (void)setupConstraints
{
    NSString *format = nil;
    if (self.titleLabel.text) {
        format = @"V:|-80-[title]-40-[description]-50-[button]";
    } else {
        format = @"V:|-80-[description]-50-[button]";
    }

    NSDictionary *buttonsDict = @{@"button" : self.button};
    NSDictionary *viewsDict = @{@"title" : self.titleLabel,
                                @"description" : self.descriptionLabel};
    
    
    NSMutableDictionary *combined = [NSMutableDictionary dictionaryWithDictionary:buttonsDict];
    [combined addEntriesFromDictionary:viewsDict];

    
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:format
                                                                    options:self.layoutOptions
                                                                    metrics:nil
                                                                      views:combined];
    [self.view addConstraints:vConstraints];
    
    [viewsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *format = [NSString stringWithFormat:@"H:|-30-[%@]-30-|", key];
        NSArray *hConstraint = [NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:nil views:@{key:obj}];
        [self.view addConstraints:hConstraint];
    }];
}

- (UILabel *)titleLabel
{
    if (_titleLabel == nil) {
        _titleLabel = [UILabel cnMessageLabelForAutoLayout];
        _titleLabel.numberOfLines = 1;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.font = HEADER_FONT;
    }
    
    return _titleLabel;
}

- (UILabel *)descriptionLabel
{
    if (_descriptionLabel == nil) {
        _descriptionLabel = [UILabel cnMessageLabelForAutoLayout];
        _descriptionLabel.font = [UIFont cnSystemFontOfSize:20];
    }
    return _descriptionLabel;
}

- (UIButton *)button
{
    if (_button == nil) {
        _button = [UIButton cnTextButton];
        [_button addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        setDefaultAutoLayoutSettings(_button);
    }
    return _button;
}

- (void)buttonPressed
{
    if (self.completionBlock) {
        self.completionBlock();
    }
}

@end



@implementation CNConfirmationViewController 

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = CN_GREEN_COLOR;
    [self.button setTitle:@"Back to Dashboard" forState:UIControlStateNormal];
}

@end

@implementation CNFirstPageViewController
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.titleLabel.text = @"Hello";
        self.descriptionLabel.text = @"We help you keep track of classes that you want to take, but are already full, and notify you when a spot opens up so you can register immediately.";
        [self.button setTitle:@"Find Classes to Track" forState:UIControlStateNormal];
    }
    
    self.layoutOptions = 0;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = WELCOME_BLUE_COLOR;
    NSArray *hConstraint = [NSLayoutConstraint constraintsWithVisualFormat:@"|-[button]-|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:@{@"button" : self.button}];
    [self.view addConstraints:hConstraint];
}

@end
