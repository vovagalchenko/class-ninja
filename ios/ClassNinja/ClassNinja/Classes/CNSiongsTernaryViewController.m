//
//  CNFirstPageViewController.m
//  ClassNinja
//
//  Created by Boris Suvorov on 11/15/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNSiongsTernaryViewController.h"
#import "CNCloseButton.h"

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
        [_button addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        setDefaultAutoLayoutSettings(_button);
    }
    return _button;
}

- (void)doneButtonPressed
{
    if (self.completionBlock) {
        self.completionBlock();
    }
}

@end

@implementation CNScreenWithCloseButtonAndActionButton
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)closeButtonTapped:(id)button
{
    if (self.dissmissalCompletionBlock) {
        self.dissmissalCompletionBlock();
    }
}

- (void)setupConstraints
{
    [super setupConstraints];
    CNCloseButton *closeButton = [[CNCloseButton alloc] initWithColor:[UIColor whiteColor]];
    [self.view addSubview:closeButton];
    
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-30-[closeButton]"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(closeButton)];
    
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-17-[closeButton]"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(closeButton)];
    [self.view addConstraints:vConstraints];
    [self.view addConstraints:hConstraints];
    
    [closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
}

@end

@interface CNRequestSchoolViewController () <UITextFieldDelegate>
@property (nonatomic) UITextField *textField;
@end


@implementation CNRequestSchoolViewController

- (NSUInteger)topOffset
{
    return 50;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.textField becomeFirstResponder];
}

- (void)logTextFieldDataWithUserAction:(NSString *)action
{
    if (self.textField.text != nil) {
        [ANALYTICS logEventWithName:@"school_request"
                               type:AnalyticsEventTypeUserAction
                         attributes:@{@"school_named" : self.textField.text,
                                      @"user_action" : action}];
    }
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self logTextFieldDataWithUserAction:@"hit_return"];
    if (self.completionBlock) {
        self.completionBlock();
    }
    return YES;
}

- (void)doneButtonPressed
{
    [self logTextFieldDataWithUserAction:@"done_btn_pressed"];
    [super doneButtonPressed];
}

- (void)closeButtonTapped:(id)button
{
    [self logTextFieldDataWithUserAction:@"close_btn_pressed"];
    if (self.dissmissalCompletionBlock) {
        self.dissmissalCompletionBlock();
    }
}

- (void)setupConstraints
{
    [super setupConstraints];
    
    UITextField *textField = [[UITextField alloc] init];
    textField.backgroundColor = [UIColor whiteColor];
    textField.delegate = self;
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:textField];

    self.textField = textField;
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-30-[textField]-30-|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(textField)];
    UILabel *descriptionLabel = self.descriptionLabel;
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[descriptionLabel]-10-[textField(==30)]"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:NSDictionaryOfVariableBindings(descriptionLabel, textField)];
    [self.view addConstraints:vConstraints];
    [self.view addConstraints:hConstraints];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = WELCOME_BLUE_COLOR;
        self.descriptionLabel.text =  @"What school do you want us to add to the Class Radar?";
        [self.button setTitle:@"Done"
                     forState:UIControlStateNormal];
    }
    
    
    return self;
}


@end

@implementation CNCollegeUnderDevelopmentViewController

- (instancetype)initWithCollegeName:(NSString *)collegeName
{
    self = [super init];
    if (self) {
        self.titleLabel.text = @"Hello";
        self.view.backgroundColor = WELCOME_BLUE_COLOR;
        self.descriptionLabel.text =  [NSString stringWithFormat:@"We're hard at work adding %@ to Class Radar. You can register now to get 10 free class targets to use for %@ once it is added. We'll notify you as soon as we're done.", collegeName, collegeName];
        [self.button setTitle:@"Sign up"
                     forState:UIControlStateNormal];
    }
    
    self.layoutOptions = 0;
    
    return self;
}

@end

@implementation CNConfirmationViewController 

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = CN_GREEN_COLOR;
    [self.button setTitle:@"Done" forState:UIControlStateNormal];
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
