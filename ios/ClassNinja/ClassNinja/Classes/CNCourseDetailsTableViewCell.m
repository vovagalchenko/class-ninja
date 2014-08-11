//
//  CNCourseDetailsTableViewCell.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/10/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNCourseDetailsTableViewCell.h"

#define kDisclousureWidthAndHeight 44

#define kStatusLEDWidth 5

#define kDateTimeLabelXOffset 66
#define kDateTimeLabelYOffset 0
#define kDateTimeLabelXRightMargin (kDisclousureWidthAndHeight + 2)

#define kBorderHairlineColor            ([UIColor colorWithRed:230/255.0 green:230/255.0 blue:229/255.0 alpha:1])
#define kStatusLEDClassAvailableColor   ([UIColor colorWithRed:71/255.0 green:182/255.0 blue:73/255.0 alpha:1])
#define kStatusLEDClassClosedColor      ([UIColor colorWithRed:220/255.0 green:39/255.0 blue:39/255.0 alpha:1])

#define kDaysOFWeekColor                ([UIColor colorWithRed:180/255.0 green:180/255.0 blue:181/255.0 alpha:1])
#define kTimeOfWeekColor                ([UIColor colorWithRed:121/255.0 green:121/255.0 blue:121/255.0 alpha:1])
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
@property (nonatomic) UIView *verticalSepartionLineView;
@property (nonatomic) UILabel *dateTimeLabel;

@property (nonatomic) BOOL usedForTargetting;

@property (nonatomic) BOOL isTargetedByUser;
@property (nonatomic) BOOL isExpanded;

@property (nonatomic) UIButton *targetButton;
@property (nonatomic) UIButton *expandButton;

@property (nonatomic) UILabel *multilineDetailsLeftFieldLabel;
@property (nonatomic) UILabel *multilineDetailsRightFieldLabel;

@end

@implementation CNCourseDetailsTableViewCell

- (void)layoutSubviews
{
    self.separationLineView.frame = CGRectMake(0, 0, self.bounds.size.width, 1);
    self.verticalSepartionLineView.frame = CGRectMake(self.bounds.size.width - kDisclousureWidthAndHeight,
                                                      0,
                                                      kDisclousureWidthAndHeight,
                                                      self.bounds.size.height);
    
    self.statusLEDView.frame = CGRectMake(0, 0, kStatusLEDWidth, self.bounds.size.height);
    self.dateTimeLabel.frame = CGRectMake(kDateTimeLabelXOffset,
                                          kDateTimeLabelYOffset,
                                          self.bounds.size.width - kDateTimeLabelXOffset - kDateTimeLabelXRightMargin,
                                          kCollapsedHeight - kDateTimeLabelYOffset);
    
    // FIXME: update these frames after getting proper assets
    self.targetButton.frame = CGRectMake(kStatusLEDWidth, 11, 22, 22);
    self.expandButton.frame = CGRectMake(self.bounds.size.width - kDisclousureWidthAndHeight + 11, 11, 22, 22);
    
    self.multilineDetailsLeftFieldLabel.frame = CGRectMake(kDateTimeLabelXOffset, kCollapsedHeight, kDetailsFieldWidth, kDetailsFieldHeight);
    self.multilineDetailsRightFieldLabel.frame = CGRectMake(kStatusDetailsXOffset,
                                                            kCollapsedHeight,
                                                            self.bounds.size.width - kDateTimeLabelXRightMargin - kStatusDetailsXOffset,
                                                            kDetailsFieldHeight);
}

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier canBeTargeted:(BOOL)useForTargetting
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        _usedForTargetting = useForTargetting;

        _separationLineView = [[UIView alloc] init];
        _separationLineView.backgroundColor = kBorderHairlineColor;

        _verticalSepartionLineView = [[UIView alloc] init];
        _verticalSepartionLineView.backgroundColor = kBorderHairlineColor;
        
        _statusLEDView = [[UIView alloc] init];
        _dateTimeLabel = [[UILabel alloc] init];
        
        [self addSubview:_separationLineView];
        [self addSubview:_verticalSepartionLineView];
        [self addSubview:_targetButton];
        [self addSubview:_expandButton];
        [self addSubview:_statusLEDView];
        [self addSubview:_dateTimeLabel];
        [self addSubview:self.expandButton];
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
        [_targetButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
        [_targetButton addTarget:self action:@selector(targetButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _targetButton;
}

- (UIButton *)expandButton
{
    if (_expandButton == nil) {
        _expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_expandButton setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_expandButton addTarget:self action:@selector(expandButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _expandButton;
}

- (void)targetButtonPressed:(id)sender
{
    self.isTargetedByUser = !self.isTargetedByUser;
    UIImage *buttonImage = nil;
    if (self.isTargetedByUser) {
        buttonImage = [UIImage imageNamed:@"search"];
    } else {
        buttonImage = [UIImage imageNamed:@"close"];
    }
    
    [self.targetButton setImage:buttonImage forState:UIControlStateNormal];
}

- (void)expandButtonPressed:(id)sender
{
    self.isExpanded = !self.isExpanded;
    [self.delegate expandStateOnCell:self changeTo:self.isExpanded];
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
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
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
- (void)updateDateTimeLabelForEvent:(CNEvent *)event
{
    NSDictionary *daysOfWeekAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                          kDaysOFWeekColor, NSForegroundColorAttributeName,
                                          kDaysTimeLabelFont, NSFontAttributeName, nil];
    
    NSMutableAttributedString *daysOfWeek = [[NSMutableAttributedString alloc] initWithString:[event daysOfWeek]
                                                                                   attributes:daysOfWeekAttributes];
    NSDictionary *hoursAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                     kTimeOfWeekColor, NSForegroundColorAttributeName,
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
                                         kTimeOfWeekColor, NSForegroundColorAttributeName, nil];
    
    NSAttributedString *nonStatus = [[NSAttributedString alloc] initWithString:nonStatusString attributes:nonStatusAttributes];
    
    [status appendAttributedString:nonStatus];
    self.multilineDetailsRightFieldLabel.attributedText = status;
    self.multilineDetailsRightFieldLabel.numberOfLines = 0;
}


@end
