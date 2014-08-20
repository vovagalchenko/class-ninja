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
#define kExpandedHeight 150.0

#define kStatusDetailsXOffset 135

@interface CNCourseDetailsTableViewCell ()

@property (nonatomic) UIView *statusLEDView;
@property (nonatomic) UIView *separationLineView;
@property (nonatomic) UILabel *dateTimeLabel;

@property (nonatomic) BOOL usedForTargetting;

@property (nonatomic) UIButton *targetButton;
@property (nonatomic) UIView *expandAccessoryView;

@property (nonatomic) UILabel *multilineDetailsLeftFieldLabel;
@property (nonatomic) UILabel *multilineDetailsRightFieldLabel;

@end

@implementation CNCourseDetailsTableViewCell

- (void)layoutSubviews
{
    self.backgroundColor = kCellBackgroundColor;
    
    self.separationLineView.frame = CGRectMake(0, 0, self.bounds.size.width, 1);
    
    self.statusLEDView.frame = CGRectMake(0, 0, kStatusLEDWidth, self.bounds.size.height);
    self.dateTimeLabel.frame = CGRectMake(kDateTimeLabelXOffset,
                                          kDateTimeLabelYOffset,
                                          self.bounds.size.width - kDateTimeLabelXOffset - kDateTimeLabelXRightMargin,
                                          kCollapsedHeight - kDateTimeLabelYOffset);
    
    self.targetButton.frame = CGRectMake(kStatusLEDWidth, 1, kDisclousureWidthAndHeight, kDisclousureWidthAndHeight);
    self.expandAccessoryView.frame = CGRectMake(self.bounds.size.width - kDisclousureWidthAndHeight, 1, kDisclousureWidthAndHeight, kDisclousureWidthAndHeight);

    self.multilineDetailsLeftFieldLabel.frame = CGRectMake(kDateTimeLabelXOffset, kCollapsedHeight, kDetailsFieldWidth, kDetailsFieldHeight);
    self.multilineDetailsRightFieldLabel.frame = CGRectMake(kStatusDetailsXOffset,
                                                            kCollapsedHeight,
                                                            self.bounds.size.width - kDateTimeLabelXRightMargin - kStatusDetailsXOffset,
                                                            kDetailsFieldHeight);
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
        _dateTimeLabel.userInteractionEnabled = NO;
        
        [self addSubview:_separationLineView];
        [self addSubview:_statusLEDView];
        [self addSubview:_dateTimeLabel];
        [self addSubview:self.expandAccessoryView];
        [self addSubview:self.targetButton];
        [self addSubview:self.multilineDetailsRightFieldLabel];
        [self addSubview:self.multilineDetailsLeftFieldLabel];
        
        self.clipsToBounds = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
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
        _multilineDetailsLeftFieldLabel.text = @"Status\n\nType\n\nLocation";
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

- (void)setEvent:(CNEvent *)event
{
    if (_event != event) {
        _event = event;
        
        self.statusLEDView.backgroundColor = [self colorForEvent:event];
        [self updateCellDetailsForEvent:event];
        [self updateDateTimeLabelForEvent:event];
        [self setTargetStateTo:self.event.targetId != nil];
    }
}

+ (CGFloat)collapsedHeight
{
    return kCollapsedHeight;
}

+ (CGFloat)expandedHeight
{
    return kExpandedHeight;;
}


// real logic lives here
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setExpandedStateTo:selected];
}

- (void)updateDateTimeLabelForEvent:(CNEvent *)event
{
    NSDictionary *daysOfWeekAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          kDaysOFWeekColor, NSForegroundColorAttributeName,
                                          kDaysTimeLabelFont, NSFontAttributeName, nil];
    
    NSMutableAttributedString *daysOfWeek = [[NSMutableAttributedString alloc] initWithString:[event daysOfWeek]
                                                                                   attributes:daysOfWeekAttributes];
    NSDictionary *hoursAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     DARK_GRAY_TEXT_COLOR, NSForegroundColorAttributeName,
                                     kDaysTimeLabelFont, NSFontAttributeName, nil];
    
    NSAttributedString *hours = [[NSAttributedString alloc] initWithString:[event hours]
                                                                attributes:hoursAttributes];
    
    NSAttributedString *space = [[NSAttributedString alloc] initWithString:@"   "];
    
    [daysOfWeek appendAttributedString:space];
    [daysOfWeek appendAttributedString:hours];
    
    self.dateTimeLabel.attributedText = daysOfWeek;
}


- (void)updateCellDetailsForEvent:(CNEvent *)event
{
    NSDictionary *statusAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      kDetailsLabelFont, NSFontAttributeName,
                                      [self colorForEvent:event], NSForegroundColorAttributeName, nil];
    
    // stands next to @"Status
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] initWithString:event.status
                                                                               attributes:statusAttributes];
    
    // stands next to "\nType\nLocation"
    NSString *nonStatusString = [NSString stringWithFormat:@"\n\n%@\n\n%@", event.eventType, event.location];
    
    NSDictionary *nonStatusAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                         kDetailsLabelFont, NSFontAttributeName,
                                         DARK_GRAY_TEXT_COLOR, NSForegroundColorAttributeName, nil];
    
    NSAttributedString *nonStatus = [[NSAttributedString alloc] initWithString:nonStatusString attributes:nonStatusAttributes];
    
    [status appendAttributedString:nonStatus];
    self.multilineDetailsRightFieldLabel.attributedText = status;
    self.multilineDetailsRightFieldLabel.numberOfLines = 0;
}

@end
