//
//  CNGenericSelectionTableViewCell.m
//  ClassNinja
//
//  Created by Boris Suvorov on 8/2/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNGenericSelectionTableViewCell.h"

#define kFontSize 14

@interface CNGenericSelectionTableViewCell ()
@property (nonatomic) UIView *separatorLine;
@end

@implementation CNGenericSelectionTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    self.separatorLine = [[UIView alloc] init];
    self.separatorLine.backgroundColor = [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:229.0/255.0 alpha:1.0];
    self.textLabel.numberOfLines = 2;
    [self addSubview:self.separatorLine];
    
    return self;
}

- (void)layoutSubviews
{
    CGSize cellSize = self.bounds.size;
    CGFloat xOffset = 21;
    [self.textLabel setFrame:CGRectMake(xOffset, 0, cellSize.width - 2 * xOffset, cellSize.height)];
    [self.separatorLine setFrame:CGRectMake(0, 0, cellSize.width, 1)];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected) {
        self.backgroundColor = [UIColor colorWithRed:239/255.0 green:242/255.0 blue:246/255.0 alpha:1.0];
        self.textLabel.textColor = [UIColor colorWithRed:54/255.0 green:91/255.0 blue:145/255.0 alpha:1.0];
        self.textLabel.font = [UIFont cnBoldSystemFontOfSize:kFontSize];
    } else {
        self.backgroundColor = [UIColor whiteColor];
        self.textLabel.textColor = [UIColor colorWithRed:90/255.0 green:91/255.0 blue:91/255.0 alpha:1.0];
        self.textLabel.font = [UIFont cnSystemFontOfSize:kFontSize];
    }
}

@end
