//
//  CNCourseDetailsTableViewCell.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/10/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNCourseDetailsTableViewCell.h"

#define kDisclousureWidthAndHeight 43

#define kCellBackgroundColor            ([UIColor colorWithWhite:250/255.0 alpha:1])
#define kBorderHairlineColor            ([UIColor colorWithRed:230/255.0 green:230/255.0 blue:229/255.0 alpha:1])

#define kStatusLEDWidth 5

#define kDateTimeLabelXOffset 66
#define kDateTimeLabelYOffset 0
#define kDateTimeLabelXRightMargin (kDisclousureWidthAndHeight + 3)

#define kStatusLEDClassAvailableColor   ([UIColor colorWithRed:71/255.0 green:182/255.0 blue:73/255.0 alpha:1])
#define kStatusLEDClassClosedColor      ([UIColor colorWithRed:220/255.0 green:39/255.0 blue:39/255.0 alpha:1])

#define kDaysOFWeekColor                ([UIColor colorWithRed:180/255.0 green:180/255.0 blue:181/255.0 alpha:1])
#define kDaysTimeLabelFont              ([UIFont cnBoldSystemFontOfSize:12.0])
#define kDetailsLabelFont               ([UIFont cnSystemFontOfSize:12.0])

#define kDetailsFieldWidth 55
#define kDetailsFieldHeight 80

#define kCollapsedHeight 44.0
#define kExpandedHeight 114.0

#define kLabelTypeOffsetX   56.0
#define kLabelTypeOffsetY   0
#define kLabelTypeHeight    44.0
#define kLabelTypeWidth     40.0

#define kStatusDetailsXOffset 135

#define kSchedulSlotOffsetX 110
#define kSchedulSlotRightPadding 30
#define kScheduleFirstSlotOffsetY 16
#define kScheduleYDistanceBetweenSlots 10
#define kSlotViewHeight 12
#define kSlotViewDayOfWeeksWidth 30
#define kSlotViewSpaceBetweenTimeAnDay 6

@interface CNScheduelSlotView : UIView
@property (nonatomic) UILabel *daysOfWeekLabel;
@property (nonatomic) UILabel *hoursLabel;
@end

@implementation CNScheduelSlotView
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
        
        self.hoursLabel.text = slot.hours;
        self.daysOfWeekLabel.text = slot.daysOfWeek;
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

@property (nonatomic) UIView *statusLEDView;
@property (nonatomic) UIView *separationLineView;
@property (nonatomic) UILabel *dateTimeLabel;

@property (nonatomic) BOOL usedForTargetting;

@property (nonatomic) UIButton *targetButton;
@property (nonatomic) UIView *expandAccessoryView;

@property (nonatomic) UILabel *multilineDetailsLeftFieldLabel;
@property (nonatomic) UILabel *multilineDetailsRightFieldLabel;

@property (nonatomic) UILabel *typeLabel;

@property (nonatomic) NSMutableArray *scheduleSlotSubviews;

@end

@implementation CNCourseDetailsTableViewCell

- (void)layoutSubviews
{
    self.backgroundColor = kCellBackgroundColor;
    
    self.typeLabel.frame = CGRectMake(kLabelTypeOffsetX, kLabelTypeOffsetY, kLabelTypeWidth, kLabelTypeHeight);
    self.separationLineView.frame = CGRectMake(0, 0, self.bounds.size.width, 1);
    self.statusLEDView.frame = CGRectMake(0, 0, kStatusLEDWidth, self.bounds.size.height);
    
    self.targetButton.frame = CGRectMake(kStatusLEDWidth, 1, kDisclousureWidthAndHeight, kDisclousureWidthAndHeight);
    self.expandAccessoryView.frame = CGRectMake(self.bounds.size.width - kDisclousureWidthAndHeight, 1, kDisclousureWidthAndHeight, kDisclousureWidthAndHeight);

    [self layoutScheduleSlotsSubviews];
    
//    self.multilineDetailsLeftFieldLabel.frame = CGRectMake(kDateTimeLabelXOffset, kCollapsedHeight, kDetailsFieldWidth, kDetailsFieldHeight);
//    self.multilineDetailsRightFieldLabel.frame = CGRectMake(kStatusDetailsXOffset,
//                                                            kCollapsedHeight,
//                                                            self.bounds.size.width - kDateTimeLabelXRightMargin - kStatusDetailsXOffset,
//                                                            kDetailsFieldHeight);
}
- (void)prepareForReuse
{
    for (UIView *view in self.scheduleSlotSubviews) {
        [view removeFromSuperview];
    }
    self.scheduleSlotSubviews = nil;
}
- (void)setEvent:(CNEvent *)event
{
    if (_event != event) {
        _event = event;
        
        self.statusLEDView.backgroundColor = [self colorForEvent:event];
        self.typeLabel.text = event.eventType;
        
        [self addSubviewforEventScheduleSlots:event.scheduleSlots];
        [self updateCellDetailsForEvent:event];
        [self updateDateTimeLabelForEvent:event];
        [self setTargetStateTo:self.event.targetId != nil];
    }
}

- (void)layoutScheduleSlotsSubviews
{
    CGFloat width = self.bounds.size.width - kSchedulSlotOffsetX - kSchedulSlotRightPadding;
    for (int i = 0; i < self.scheduleSlotSubviews.count; i++) {
        UIView *view = [self.scheduleSlotSubviews objectAtIndex:i];
        view.frame = CGRectMake(kSchedulSlotOffsetX, kScheduleFirstSlotOffsetY + i * (kScheduleYDistanceBetweenSlots + kSlotViewHeight) , width, kSlotViewHeight);
    }
}

- (void)addSubviewforEventScheduleSlots:(NSArray *)scheduleSlots
{
    self.scheduleSlotSubviews = [NSMutableArray array];
    for (CNScheduleSlot *slot in scheduleSlots) {
        CNScheduelSlotView *slotView = [[CNScheduelSlotView alloc] initWithSlot:slot];
        [self.scheduleSlotSubviews addObject:slotView];
        [self addSubview:slotView];
    }
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier usedForTargetting:(BOOL)usedForTargetting
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _usedForTargetting = usedForTargetting;

        _separationLineView = [[UIView alloc] init];
        _separationLineView.backgroundColor = kBorderHairlineColor;
        
        _statusLEDView = [[UIView alloc] init];
        _dateTimeLabel = [[UILabel alloc] init];
        _dateTimeLabel.numberOfLines = 0;
        _dateTimeLabel.userInteractionEnabled = NO;
        
        [self addSubview:_separationLineView];
        [self addSubview:_statusLEDView];
        [self addSubview:_dateTimeLabel];
        [self addSubview:self.expandAccessoryView];
        [self addSubview:self.targetButton];
//        [self addSubview:self.multilineDetailsRightFieldLabel];
//        [self addSubview:self.multilineDetailsLeftFieldLabel];

        [self addSubview:self.typeLabel];
        
        self.clipsToBounds = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
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
    }
    
    return _multilineDetailsRightFieldLabel;
}

- (UILabel *)multilineDetailsLeftFieldLabel
{
    if (_multilineDetailsLeftFieldLabel == nil) {
        _multilineDetailsLeftFieldLabel = [[UILabel alloc] init];
        _multilineDetailsLeftFieldLabel.text = @"Status\n\nType";
        _multilineDetailsLeftFieldLabel.numberOfLines = 0;
        _multilineDetailsLeftFieldLabel.font = kDetailsLabelFont;
        _multilineDetailsLeftFieldLabel.textColor = kDaysOFWeekColor;
        _multilineDetailsLeftFieldLabel.clipsToBounds = YES;
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
    [UIView animateWithDuration:ANIMATION_DURATION animations:accessoryViewFlip];
    [self.delegate expandStateOnCell:self changedTo:isExpanded];
}

- (UIColor *)colorForEvent:(CNEvent *)event
{
    if ([event isClosed]) {
        return kStatusLEDClassClosedColor;
    } else {
        return kStatusLEDClassAvailableColor;
    }
}

+ (CGFloat)collapsedHeightForEvent:(CNEvent *)event
{
    return kCollapsedHeight + 20 * (event.scheduleSlots.count - 1);
}

+ (CGFloat)expandedHeightForEvent:(CNEvent *)event
{
    return kExpandedHeight + (20 + 66) * (event.scheduleSlots.count - 1);
}


// real logic lives here
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setExpandedStateTo:selected];
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


- (void)updateCellDetailsForEvent:(CNEvent *)event
{
    NSDictionary *statusAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      kDetailsLabelFont, NSFontAttributeName,
                                      [self colorForEvent:event], NSForegroundColorAttributeName, nil];
    
    // stands next to @"Status
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] initWithString:event.status
                                                                               attributes:statusAttributes];
    
    // stands next to "\nType"
    NSString *nonStatusString = [NSString stringWithFormat:@"\n\n%@", event.eventType];
    
    NSDictionary *nonStatusAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         kDetailsLabelFont, NSFontAttributeName,
                                         DARK_GRAY_TEXT_COLOR, NSForegroundColorAttributeName, nil];
    
    NSAttributedString *nonStatus = [[NSAttributedString alloc] initWithString:nonStatusString attributes:nonStatusAttributes];
    
    [status appendAttributedString:nonStatus];
    self.multilineDetailsRightFieldLabel.attributedText = status;
    self.multilineDetailsRightFieldLabel.numberOfLines = 0;
}

@end
