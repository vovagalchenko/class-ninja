//
//  CNFirstPageViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 11/15/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNFirstPageViewController.h"



@interface UIButton (CNAdditions)
+ (instancetype)cnTextButton;
+ (instancetype)cnTextButtonForAutolayout;
@end

@implementation UIButton (CNAdditions)
+ (instancetype)cnTextButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.font = BUTTON_FONT;
    return button;
}

+ (instancetype)cnTextButtonForAutolayout
{
    UIButton *button = [self cnTextButton];
    
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [button setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [button setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    return button;
}
@end


@interface CNSiongsTernaryViewController ()
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *descriptionLabel;
@property (nonatomic) UIButton *button;
@end

@implementation CNSiongsTernaryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.descriptionLabel];
    [self.view addSubview:self.button];
    [self setupConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)setupConstraints
{
    NSString *format = @"V:|-80-[title]-40-[description]-50-[button]";

    NSDictionary *buttonsDict = @{@"button" : self.button};
    NSDictionary *viewsDict = @{@"title" : self.titleLabel,
                                @"description" : self.descriptionLabel};
    
    
    NSMutableDictionary *combined = [NSMutableDictionary dictionaryWithDictionary:buttonsDict];
    [combined addEntriesFromDictionary:viewsDict];

    
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:format
                                                                    options:0
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
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.numberOfLines = 1;
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.font = HEADER_FONT;
        _titleLabel.textColor = [UIColor whiteColor];
        
        setDefaultAutoLayoutSettings(_titleLabel);
    }
    
    return _titleLabel;
}

- (UILabel *)descriptionLabel
{
    if (_descriptionLabel == nil) {
        _descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.numberOfLines = 0;
        _descriptionLabel.textAlignment = NSTextAlignmentLeft;
        _descriptionLabel.font = [UIFont cnSystemFontOfSize:20];
        _descriptionLabel.textColor = [UIColor whiteColor];
        
        setDefaultAutoLayoutSettings(_descriptionLabel);
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

@implementation CNFirstPageViewController
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.titleLabel.text = @"Hello";
        self.descriptionLabel.text = @"We help you keep track of classes that you want to take, but are already full, and notify you when a spot opens up so you can register immediately";
        [self.button setTitle:@"Find Class to Track" forState:UIControlStateNormal];
    }
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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


@end
