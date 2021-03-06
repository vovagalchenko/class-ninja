//
//  CNCourseDetailsTableViewCell.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/10/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNCourseDetailsTableViewCell.h"
#import "CNCloseButton.h"
#import "CNActivityIndicator.h"

#define kDisclousureWidthAndHeight 22
#define kDisclousureRightPadding 6

#define kTargetButtonWidthAndHeight 43
#define kTargetOffsetX 7.0

#define kLeftShiftForMainScreen 35

#define kCellBackgroundColor            ([UIColor colorWithWhite:250/255.0 alpha:1])
#define kBorderHairlineColor            ([UIColor colorWithRed:230/255.0 green:230/255.0 blue:229/255.0 alpha:1])

#define kStatusLEDWidth 12
#define kStatusLEDHeight 12

#define kDateTimeLabelXOffset 18
#define kDateTimeLabelYOffset 0
#define kDateTimeLabelXRightMargin (kTargetButtonWidthAndHeight + 3)

#define kStatusLEDClassAvailableColor   ([UIColor colorWithRed:71/255.0 green:182/255.0 blue:73/255.0 alpha:1])
#define kStatusLEDClassClosedColor      ([UIColor colorWithRed:220/255.0 green:39/255.0 blue:39/255.0 alpha:1])
#define kStatusLEDClassWaitlistColor    ([UIColor colorWithRed:255/255.0 green:176/255.0 blue:0/255.0 alpha:1])
#define kStatusLEDClassCancelledColor   ([UIColor colorWithRed:120./255.0 green:120./255.0 blue:120./255.0 alpha:1])

#define kDaysOFWeekColor                ([UIColor colorWithRed:180/255.0 green:180/255.0 blue:181/255.0 alpha:1])
#define kDaysTimeLabelFont              ([UIFont systemFontOfSize:14.0])
#define kDetailsLabelFont               ([UIFont systemFontOfSize:14.0])

#define kCollapsedHeight 44.0
#define kExpandedHeight 214.0

#define kDetailsFieldMaxHeight (1000)
#define kDetailsFieldWidth 70

#define kLabelTypeOffsetX   (50)
#define kLabelTypeOffsetY   0
#define kLabelTypeHeight    44.0
#define kLabelTypeWidth     40.0

#define kStatusDetailsXOffset (kDetailsFieldWidth + kDateTimeLabelXOffset)
#define kStatusDetailsPadding 10

#define kScheduleSlotOffsetX 90
#define kScheduleSlotRightPadding (2 * kDisclousureRightPadding + kDisclousureRightPadding)
#define kScheduleFirstSlotOffsetY 16
#define kScheduleYDistanceBetweenSlots 10
#define kSlotViewHeight 12
#define kSlotViewDayOfWeeksWidth 35
#define kSlotViewSpaceBetweenTimeAnDay 3

#define kCellBottomPadding 18

#define kParagraphLineSpacing 6
#define kRemoveFromTargetButtonHeight 44

@interface CNScheduleSlotView : UIView
@property (nonatomic) UILabel *daysOfWeekLabel;
@property (nonatomic) UILabel *hoursLabel;
@end

@implementation CNScheduleSlotView
- (UILabel *)daysOfWeekLabel
{
    if (_daysOfWeekLabel == nil) {
        _daysOfWeekLabel = [[UILabel alloc] init];
        _daysOfWeekLabel.numberOfLines = 1;
        _daysOfWeekLabel.font = kDetailsLabelFont;
        _daysOfWeekLabel.textAlignment = NSTextAlignmentLeft;
        _daysOfWeekLabel.textColor = DARK_GRAY_TEXT_COLOR;
    }
    
    return _daysOfWeekLabel;
}

- (UILabel *)hoursLabel
{
    if (_hoursLabel == nil) {
        _hoursLabel = [[UILabel alloc] init];
        _hoursLabel.numberOfLines = 1;
        _hoursLabel.font = kDetailsLabelFont;
        _hoursLabel.textAlignment = NSTextAlignmentLeft;
        _hoursLabel.textColor = DARK_GRAY_TEXT_COLOR;
    }
    return _hoursLabel;
}

- (instancetype)initWithSlot:(CNScheduleSlot *)slot
{
    self = [super init];
    if (self) {
        [self addSubview:self.hoursLabel];
        [self addSubview:self.daysOfWeekLabel];
        
        if ([slot.daysOfWeek isEqualToString:@"UNSCHED"] ) {
            self.hoursLabel.text = @"UNSCHED";
        } else {
            self.hoursLabel.text = slot.hours;
            self.daysOfWeekLabel.text = slot.daysOfWeek;
        }
        
    }
    return self;
}


- (void)layoutSubviews
{
    self.daysOfWeekLabel.frame = CGRectMake(0, 0, kSlotViewDayOfWeeksWidth, kSlotViewHeight);
    self.hoursLabel.frame = CGRectMake(kSlotViewDayOfWeeksWidth + kSlotViewSpaceBetweenTimeAnDay, 0,
                                       self.bounds.size.width - (kSlotViewDayOfWeeksWidth + kSlotViewSpaceBetweenTimeAnDay),
                                       kSlotViewHeight);
}

@end


@interface CNCourseDetailsTableViewCell ()

@property (nonatomic) UIImageView *statusLEDView;
@property (nonatomic) UIView *separationLineView;
@property (nonatomic) UILabel *dateTimeLabel;

@property (nonatomic) BOOL usedForTargetting;

@property (nonatomic) UIButton *targetButton;
@property (nonatomic) CNCloseButton *removeFromTargetsButton;
@property (nonatomic) UIView *expandAccessoryView;
@property (nonatomic) CNActivityIndicator *activityIndicatorAccessoryView;
@property (nonatomic) UILabel *multilineDetailsLeftFieldLabel;
@property (nonatomic) UILabel *multilineDetailsRightFieldLabel;
@property (nonatomic) UILabel *typeLabel;

@property (nonatomic) NSMutableArray *scheduleSlotSubviews;

@property (nonatomic) UIView *myContentView;
@property (nonatomic) UIView *highlightBackgroundView;

@end

@implementation CNCourseDetailsTableViewCell

- (void)layoutSubviews
{
    self.backgroundColor = kCellBackgroundColor;
    self.highlightBackgroundView.frame = self.bounds;
    self.myContentView.frame =  CGRectMake(0, 0, self.bounds.size.width,
                                         self.isSelected? [[self class] expandedHeightForEvent:self.event
                                                                                         width:self.bounds.size.width
                                                                              usedForTargeting:self.usedForTargetting] :
                                                          [[self class] collapsedHeightForEvent:self.event]);
    
    self.separationLineView.frame = CGRectMake(0, 0, self.bounds.size.width, 1);
    self.statusLEDView.frame = CGRectMake(0, 0, kStatusLEDWidth, kStatusLEDHeight);

    CGFloat leftShift = 0;
    
    if (self.usedForTargetting == NO) {
        leftShift = kLeftShiftForMainScreen;
        self.targetButton.hidden = YES;
        CGFloat expandedHeight = [[self class] expandedHeightForEvent:self.event
                                                                width:self.bounds.size.width
                                                     usedForTargeting:self.usedForTargetting];
        
        self.removeFromTargetsButton.frame = CGRectMake(0,
                                                        expandedHeight - kRemoveFromTargetButtonHeight,
                                                        self.bounds.size.width,
                                                        kRemoveFromTargetButtonHeight);
    } else {
        self.removeFromTargetsButton.hidden = YES;
        self.targetButton.frame = CGRectMake(kTargetOffsetX, 1, kTargetButtonWidthAndHeight, kTargetButtonWidthAndHeight);
    }

    self.typeLabel.frame = CGRectMake(kLabelTypeOffsetX - leftShift, kLabelTypeOffsetY, kLabelTypeWidth, kLabelTypeHeight);

    [self layoutScheduleSlotsSubviewsWithLeftShift:leftShift];
    
    CGFloat yOffset = [[self class] collapsedHeightForEvent:self.event];
    
    NSAttributedString *stringToSize = self.multilineDetailsLeftFieldLabel.attributedText;
    CGRect boundingRect = [stringToSize boundingRectWithSize:CGSizeMake(kDetailsFieldWidth, kDetailsFieldMaxHeight)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                     context:nil];
    self.multilineDetailsLeftFieldLabel.frame = CGRectMake(kDateTimeLabelXOffset,
                                                           yOffset,
                                                           ceilf(boundingRect.size.width),
                                                           ceilf(boundingRect.size.height));
    
    stringToSize = self.multilineDetailsRightFieldLabel.attributedText;
    CGFloat width = self.bounds.size.width - kStatusDetailsXOffset - kStatusDetailsPadding;
    boundingRect = [stringToSize boundingRectWithSize:CGSizeMake(width, kDetailsFieldMaxHeight)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                              context:nil];
    self.multilineDetailsRightFieldLabel.frame = CGRectMake(kStatusDetailsXOffset,
                                                            yOffset,
                                                            ceilf(boundingRect.size.width),
                                                            ceilf(boundingRect.size.height));

    self.expandAccessoryView.frame = CGRectMake(self.bounds.size.width - kDisclousureWidthAndHeight - kDisclousureRightPadding, 11, kDisclousureWidthAndHeight, kDisclousureWidthAndHeight);
    self.activityIndicatorAccessoryView.frame = self.expandAccessoryView.frame;
}

- (void)setEvent:(CNEvent *)event
{
    // The clearing of scheduleSlotSubviews could go into prepareToReuse, however, it's nice to keep setEvent idempotent
    for (UIView *view in self.scheduleSlotSubviews) {
        [view removeFromSuperview];
    }
    self.scheduleSlotSubviews = nil;
    
    _event = event;
    
    self.statusLEDView.image = [[self class] ledImageForEvent:event];
    self.typeLabel.text = event.eventSectionType;
        
    self.multilineDetailsRightFieldLabel.attributedText = [[self class] attributedStringForEventDetails:event];
    [self updateDateTimeLabelForEvent:event];
    [self updateTargetButtonForEvent:event];
    [self addSubviewforEventScheduleSlots:event.scheduleSlots];
}

- (void)updateTargetButtonForEvent:(CNEvent *)event
{
    if (self.event.targetId != nil) {
        UIImage *buttonImage = [UIImage imageNamed:@"checkbox-tracked"];
        [self.targetButton setImage:buttonImage forState:UIControlStateNormal];
        self.targetButton.enabled = NO;
    } else if ([self.event isCancelled]) {
        UIImage *buttonImage = [UIImage imageNamed:@"checkbox-disabled"];
        [self.targetButton setImage:buttonImage forState:UIControlStateNormal];
        self.targetButton.enabled = NO;
    }
}

- (void)layoutScheduleSlotsSubviewsWithLeftShift:(CGFloat)leftShift
{
    CGFloat width = self.bounds.size.width - (kScheduleSlotOffsetX - leftShift) - kScheduleSlotRightPadding;
    
    for (int i = 0; i < self.scheduleSlotSubviews.count; i++) {
        UIView *view = [self.scheduleSlotSubviews objectAtIndex:i];
        view.frame = CGRectMake(kScheduleSlotOffsetX - leftShift,
                                kScheduleFirstSlotOffsetY + i * (kScheduleYDistanceBetweenSlots + kSlotViewHeight),
                                width, kSlotViewHeight);
    }
}

- (void)addSubviewforEventScheduleSlots:(NSArray *)scheduleSlots
{
    self.scheduleSlotSubviews = [NSMutableArray array];
    for (CNScheduleSlot *slot in scheduleSlots) {
        CNScheduleSlotView *slotView = [[CNScheduleSlotView alloc] initWithSlot:slot];
        [self.scheduleSlotSubviews addObject:slotView];
        [self addSubview:slotView];
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [self initWithReuseIdentifier:reuseIdentifier usedForTargetting:NO];
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier usedForTargetting:(BOOL)usedForTargetting
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _usedForTargetting = usedForTargetting;

        _separationLineView = [[UIView alloc] init];
        _separationLineView.backgroundColor = kBorderHairlineColor;
        
        _statusLEDView = [[UIImageView alloc] init];
        _dateTimeLabel = [[UILabel alloc] init];
        _dateTimeLabel.numberOfLines = 0;
        _dateTimeLabel.userInteractionEnabled = NO;
        
        _highlightBackgroundView = [[UIView alloc] init];
        _highlightBackgroundView.backgroundColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:1.0];
        
        _activityIndicatorAccessoryView = [[CNActivityIndicator alloc] initWithFrame:CGRectZero presentedOnLightBackground:YES];
        _activityIndicatorAccessoryView.alpha = 0;
        
        _myContentView = [[UIView alloc] init];
        _myContentView.opaque = YES;
        _myContentView.backgroundColor = [UIColor whiteColor];
        _myContentView.clipsToBounds = YES;
        [self addSubview:_myContentView];
        
        [_myContentView addSubview:_highlightBackgroundView];
        [_myContentView addSubview:_separationLineView];
        [_myContentView addSubview:_statusLEDView];
        [_myContentView addSubview:_dateTimeLabel];
        [_myContentView addSubview:self.removeFromTargetsButton];
        [_myContentView addSubview:self.expandAccessoryView];
        [_myContentView addSubview:_activityIndicatorAccessoryView];
        [_myContentView addSubview:self.targetButton];
        [_myContentView addSubview:self.multilineDetailsLeftFieldLabel];
        [_myContentView addSubview:self.multilineDetailsRightFieldLabel];
        [_myContentView addSubview:self.typeLabel];

        _myContentView.clipsToBounds = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    void (^highlight)() = ^{
        self.highlightBackgroundView.alpha = highlighted;
    };
    if (animated) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:highlight];
    } else {
        highlight();
    }
}

- (UILabel *)typeLabel
{
    if (_typeLabel == nil) {
        _typeLabel = [[UILabel alloc] init];
        _typeLabel.numberOfLines = 1;
        _typeLabel.textAlignment = NSTextAlignmentLeft;
        _typeLabel.font = kDetailsLabelFont;
        _typeLabel.textColor = DARK_GRAY_TEXT_COLOR;
    }
    
    return _typeLabel;
}


- (UILabel *)multilineDetailsRightFieldLabel
{
    if (_multilineDetailsRightFieldLabel == nil) {
        _multilineDetailsRightFieldLabel = [[UILabel alloc] init];
        _multilineDetailsRightFieldLabel.text = @"";
        _multilineDetailsRightFieldLabel.numberOfLines = 0;
        _multilineDetailsRightFieldLabel.font = kDetailsLabelFont;
        _multilineDetailsRightFieldLabel.textColor = kDaysOFWeekColor;
        _multilineDetailsRightFieldLabel.clipsToBounds = YES;
        _multilineDetailsRightFieldLabel.lineBreakMode = NSLineBreakByCharWrapping;
    }
    
    return _multilineDetailsRightFieldLabel;
}

- (UILabel *)multilineDetailsLeftFieldLabel
{
    if (_multilineDetailsLeftFieldLabel == nil) {
        _multilineDetailsLeftFieldLabel = [[UILabel alloc] init];
        _multilineDetailsLeftFieldLabel.textAlignment = NSTextAlignmentLeft;
        _multilineDetailsLeftFieldLabel.numberOfLines = 0;
        _multilineDetailsLeftFieldLabel.textColor = kDaysOFWeekColor;
        _multilineDetailsLeftFieldLabel.clipsToBounds = YES;
        
        NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
        [paragrahStyle setLineSpacing:kParagraphLineSpacing];
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    paragrahStyle, NSParagraphStyleAttributeName,
                                    kDetailsLabelFont, NSFontAttributeName,
                                    nil];
        
        NSString *text = @"Status\nSection\nLocation";
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];

        _multilineDetailsLeftFieldLabel.attributedText = attributedString;
    }
    
    return _multilineDetailsLeftFieldLabel;
}

- (UIButton *)targetButton
{
    if (_targetButton == nil) {
        _targetButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _targetButton.backgroundColor = [UIColor clearColor];
        [_targetButton setImage:[UIImage imageNamed:@"checkbox-unchecked"] forState:UIControlStateNormal];
        [_targetButton setImage:[UIImage imageNamed:@"checkbox-checked"] forState:UIControlStateSelected];
        [_targetButton addTarget:self action:@selector(targetButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _targetButton;
}


- (void)targetButtonPressed:(id)sender
{
    BOOL isTargetedByUser = !self.targetButton.isSelected;
    [self setTargetStateTo:isTargetedByUser];
}


- (UIButton *)removeFromTargetsButton
{
    if (_removeFromTargetsButton == nil) {
        _removeFromTargetsButton = [[CNCloseButton alloc] initWithColor:[UIColor redColor]];
        [_removeFromTargetsButton setTitle:@"Remove from targets" forState:UIControlStateNormal];
        _removeFromTargetsButton.backgroundColor = [UIColor clearColor];
        _removeFromTargetsButton.titleLabel.font = [UIFont cnSystemFontOfSize:16.0];
        [_removeFromTargetsButton addTarget:self action:@selector(removeFromTargetsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _removeFromTargetsButton;
}

- (void)removeFromTargetsButtonPressed:(id)sender
{
    [self.delegate removeFromTargetsPressedIn:self];
}

- (void)setTargetStateTo:(BOOL)isTargetted
{
    self.targetButton.selected = isTargetted;
    
    UIImage *buttonImage = nil;
    if (isTargetted) {
        buttonImage = [UIImage imageNamed:@"checkbox-checked"];
    } else {
        buttonImage = [UIImage imageNamed:@"checkbox-unchecked"];
    }
    
    [self.targetButton setImage:buttonImage forState:UIControlStateNormal];
    [self.delegate targetingStateOnCell:self changedTo:isTargetted];
}

- (UIView *)expandAccessoryView
{
    if (_expandAccessoryView == nil) {
        _expandAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"expand-grey"]];
        _expandAccessoryView.contentMode = UIViewContentModeCenter;
    }
    return _expandAccessoryView;
}

- (void)setExpandedStateTo:(BOOL)isExpanded
{
    dispatch_block_t accessoryViewFlip = ^{
        // The 0.999 is a hack to make sure the accessory view rotates counter clockwise
        self.expandAccessoryView.transform = CGAffineTransformMakeRotation(isExpanded? 0.999*M_PI : 0);
    };
    if (self.expandAccessoryView.layer.animationKeys.count > 0) [self.expandAccessoryView.layer removeAllAnimations];
    [UIView animateWithDuration:ANIMATION_DURATION animations:accessoryViewFlip];
    [self.delegate expandStateOnCell:self changedTo:isExpanded];
}

+ (UIImage *)ledImageForEvent:(CNEvent *)event
{
    if ([event isClosed]) {
        return [UIImage imageNamed:@"tab-red"];
    } else if ([event isOpened]) {
        return [UIImage imageNamed:@"tab-green"];
    } else if ([event isWaitlisted]) {
        return [UIImage imageNamed:@"tab-yellow"];
    } else if ([event isCancelled]) {
        return [UIImage imageNamed:@"tab-grey"];
    }
    
    return nil;
}

+ (UIColor *)colorForEvent:(CNEvent *)event
{
    if ([event isClosed]) {
        return kStatusLEDClassClosedColor;
    } else if ([event isOpened]){
        return kStatusLEDClassAvailableColor;
    } else if ([event isWaitlisted]){
        return kStatusLEDClassWaitlistColor;
    } else if ([event isCancelled]) {
        return kStatusLEDClassCancelledColor;
    }
    
    return nil;
}

+ (CGFloat)collapsedHeightForEvent:(CNEvent *)event
{
    if (event.scheduleSlots.count > 0) {
        return kCollapsedHeight + 20 * (event.scheduleSlots.count - 1);
    } else {
        return kCollapsedHeight;
    }
}

+ (CGFloat)expandedHeightForEvent:(CNEvent *)event width:(CGFloat)viewWidth usedForTargeting:(BOOL)usedForTargeting
{
    NSAttributedString *details = [self attributedStringForEventDetails:event];
    CGFloat width = viewWidth - kStatusDetailsXOffset - kStatusDetailsPadding;
    CGRect rightBoundingRect = [details boundingRectWithSize:CGSizeMake(width, kDetailsFieldMaxHeight)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                context:nil];
    
    CGFloat extraHeight = rightBoundingRect.size.height;
    if (usedForTargeting == NO) {
        extraHeight += (kRemoveFromTargetButtonHeight - kCellBottomPadding);
    }
    return  [self collapsedHeightForEvent:event] +
            (ceilf(extraHeight)+1) +
            kCellBottomPadding;
}


// real logic lives here
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setExpandedStateTo:selected];
}

- (void)setProcessing:(BOOL)processing
{
    [UIView animateWithDuration:ANIMATION_DURATION animations:^
     {
         self.activityIndicatorAccessoryView.alpha = processing;
         self.expandAccessoryView.alpha = !processing;
     }];
}

- (void)updateDateTimeLabelForEvent:(CNEvent *)event
{
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] init];
    for (CNScheduleSlot *slot in event.scheduleSlots) {
        NSDictionary *daysOfWeekAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                              kDaysOFWeekColor, NSForegroundColorAttributeName,
                                              kDaysTimeLabelFont, NSFontAttributeName, nil];
        
        NSMutableAttributedString *daysOfWeek = [[NSMutableAttributedString alloc] initWithString:[slot daysOfWeek]
                                                                                       attributes:daysOfWeekAttributes];
        NSDictionary *hoursAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         DARK_GRAY_TEXT_COLOR, NSForegroundColorAttributeName,
                                         kDaysTimeLabelFont, NSFontAttributeName, nil];
        
        NSAttributedString *hours = [[NSAttributedString alloc] initWithString:[slot hours]
                                                                    attributes:hoursAttributes];
        
        NSAttributedString *location = [[NSAttributedString alloc] initWithString:[slot location]
                                                                       attributes:hoursAttributes];
        
        
        NSAttributedString *space = [[NSAttributedString alloc] initWithString:@"   "];
        NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:@"\n"];
        
        [daysOfWeek appendAttributedString:space];
        [daysOfWeek appendAttributedString:hours];
        [daysOfWeek appendAttributedString:newLine];
        [daysOfWeek appendAttributedString:location];

        [resultString appendAttributedString:daysOfWeek];
        [resultString appendAttributedString:newLine];
    }
    self.dateTimeLabel.attributedText = resultString;
}

+ (NSAttributedString *)attributedStringForEventDetails:(CNEvent *)event
{
    NSDictionary *statusAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      kDetailsLabelFont, NSFontAttributeName,
                                      [self colorForEvent:event], NSForegroundColorAttributeName, nil];
    
    // stands next to @"Status
    NSAttributedString *status = [[NSAttributedString alloc] initWithString:event.status
                                                                 attributes:statusAttributes];
    
    // stands next to "\nSection"
    NSDictionary *setionAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         kDetailsLabelFont, NSFontAttributeName,
                                         DARK_GRAY_TEXT_COLOR, NSForegroundColorAttributeName, nil];

    NSString *sectionId = [event eventSectionId];
    NSAttributedString *section = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@\n", sectionId]
                                                                  attributes:setionAttributes];
    
    
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] initWithAttributedString:status];
    [resultString appendAttributedString:section];

    
    NSMutableAttributedString *timesAndLocation = [[NSMutableAttributedString alloc] init];
    NSDictionary *daysTimeAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        kDetailsLabelFont, NSFontAttributeName,
                                        DARK_GRAY_TEXT_COLOR,NSForegroundColorAttributeName, nil];
    NSDictionary *locationAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        kDetailsLabelFont, NSFontAttributeName,
                                        LIGHT_GRAY_TEXT_COLOR,NSForegroundColorAttributeName, nil];
    

    if (event.scheduleSlots.count == 1){
        CNScheduleSlot *slot = [event.scheduleSlots firstObject];
        NSString *locationString = [NSString stringWithFormat:@"%@", [slot location]];
        NSMutableAttributedString *location = [[NSMutableAttributedString alloc] initWithString:locationString
                                                                                     attributes:daysTimeAttributes];
        [timesAndLocation appendAttributedString:location];
    } else {
        for (int i = 0; i < event.scheduleSlots.count; i++) {
            CNScheduleSlot *slot = [event.scheduleSlots objectAtIndex:i];
            
            NSString *daysTimeString = [NSString stringWithFormat:@"%@ %@", [slot daysOfWeek], [slot hours]];
            NSString *locationString = [NSString stringWithFormat:@"%@\n", [slot location]];
            if (i+1 < event.scheduleSlots.count) {
                daysTimeString = [daysTimeString stringByAppendingString:@"\n"];
            }
            
            NSMutableAttributedString *daysTime = [[NSMutableAttributedString alloc] initWithString:daysTimeString
                                                                                         attributes:locationAttributes];
            NSMutableAttributedString *location = [[NSMutableAttributedString alloc] initWithString:locationString
                                                                                         attributes:daysTimeAttributes];
            [timesAndLocation appendAttributedString:location];
            [timesAndLocation appendAttributedString:daysTime];
        }
    }

    
    [resultString appendAttributedString:timesAndLocation];

    NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
    [paragrahStyle setLineSpacing:kParagraphLineSpacing];
    [resultString addAttribute:NSParagraphStyleAttributeName value:paragrahStyle range:NSMakeRange(0, [resultString length])];
    
    return resultString;
}

@end
