//
//  CNNumberEntryTextField.m
//  ClassNinja
//
//  Created by Vova Galchenko on 8/2/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "CNNumberEntryTextField.h"
#import "AppearanceConstants.h"

@interface CNNumberEntryTextField()

@property (nonatomic, assign) NSUInteger maxNumDigits;

@end

@implementation CNNumberEntryTextField

- (instancetype)init
{
    if (self = [super init]) {
        self.keyboardType = UIKeyboardTypeNumberPad;
        self.keyboardAppearance = UIKeyboardAppearanceDefault;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.delegate = self;
        self.maxNumDigits = 0;
        self.groupArray = nil;
        
        [self addTarget:self
                 action:@selector(setNeedsDisplay)
       forControlEvents:UIControlEventEditingChanged];
    }
    return self;
}

- (void)setGroupArray:(NSArray *)groupArray
{
    ASSERT_MAIN_THREAD();
    _groupArray = groupArray;
    self.maxNumDigits = totalNumberOfDigits(groupArray);
    [self setNeedsDisplay];
}

#pragma mark - Overriding UITextField shit

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(0.0, FOCAL_LABEL_TEXT_SIZE);
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    // Don't want to display the blinking cursor
    return CGRectZero;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if ([string rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound &&
        newString.length <= self.maxNumDigits) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return NO;
}

- (UITextRange *)selectedTextRange
{
    // Prevent selection
    return nil;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
    // We'll draw our own text, thankyouverymuch
    return CGRectZero;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat placeholderLineThickness = 1.0;
    CGContextSetLineWidth(ctx, placeholderLineThickness);
    [[UIColor whiteColor] setStroke];
    CGFloat lineY = self.bounds.size.height - placeholderLineThickness;
    CNNumberEntryTextRedlining redlining = CNNumberEntryTextRedliningMake(self.bounds.size.width, self.groupArray);
    CGPoint currentPoint = CGPointMake(redlining.sideMargin, lineY);
    CGContextMoveToPoint(ctx, currentPoint.x, currentPoint.y);
    NSUInteger numDigitsTyped = self.text.length;
    NSUInteger currentDigitIndex = 0;
    for (NSNumber *numDashesInGroup in self.groupArray) {
        NSUInteger numDashes = [numDashesInGroup unsignedIntegerValue];
        for (int i = 0; i < numDashes; i++) {
            currentPoint = CGPointMake(currentPoint.x + redlining.lengthOfPlaceholder, lineY);
            CGContextAddLineToPoint(ctx, currentPoint.x, currentPoint.y);
            CGFloat spaceLength = redlining.lengthOfSmallerSpace;
            if (i == numDashes - 1) {
                spaceLength = redlining.lengthOfLargerSpace;
            }
            if (currentDigitIndex < numDigitsTyped) {
                char digitToDraw = [self.text characterAtIndex:currentDigitIndex];
                [[NSString stringWithFormat:@"%c", digitToDraw]
                 drawInRect:CGRectMake(currentPoint.x - redlining.lengthOfPlaceholder, 0, redlining.lengthOfPlaceholder, self.bounds.size.height - placeholderLineThickness*5)
                 withAttributes:@{
                                  NSFontAttributeName            : [UIFont cnSystemFontOfSize:FOCAL_LABEL_TEXT_SIZE - placeholderLineThickness*5],
                                  NSForegroundColorAttributeName : [UIColor whiteColor],
                                  NSParagraphStyleAttributeName  : centeredParagraphStyle()
                                  }];
                [[UIColor clearColor] setStroke];
            } else if (currentDigitIndex == numDigitsTyped){
                [[UIColor whiteColor] setStroke];
            } else {
                [[[UIColor whiteColor] colorWithAlphaComponent:.5] setStroke];
            }
            currentDigitIndex++;
            CGContextStrokePath(ctx);
            currentPoint = CGPointMake(currentPoint.x + spaceLength, lineY);
            CGContextMoveToPoint(ctx, currentPoint.x, currentPoint.y);
        }
    }
}

#pragma mark - Misc. Helpers

static inline NSUInteger totalNumberOfDigits(NSArray *groupArray)
{
    NSUInteger newMaxNumDigits = 0;
    for (NSNumber *integer in groupArray) {
        newMaxNumDigits += [integer unsignedIntegerValue];
    }
    return newMaxNumDigits;
}

static inline NSParagraphStyle *centeredParagraphStyle()
{
    NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setAlignment:NSTextAlignmentCenter];
    return style;
}

struct CNNumberEntryTextRedlining {
    CGFloat lengthOfPlaceholder;
    CGFloat lengthOfSmallerSpace;
    CGFloat lengthOfLargerSpace;
    CGFloat sideMargin;
};
typedef struct CNNumberEntryTextRedlining CNNumberEntryTextRedlining;

static inline CNNumberEntryTextRedlining CNNumberEntryTextRedliningMake(CGFloat totalWidth, NSArray *groups)
{
#define AVG_PERCENT_OF_PLACEHOLDER_FOR_PADDING      0.25
#define LARGER_SPACE_RELATIVE_DELTA_TO_SMALLER      1.00
#define MAX_AVG_LENGTH_PER_DIGIT                    30.0
    NSUInteger totalNumDigits = totalNumberOfDigits(groups);
    CGFloat widthToDrawIn = MIN(MAX_AVG_LENGTH_PER_DIGIT*totalNumDigits, totalWidth);
    NSUInteger totalNumSpaces = totalNumDigits - 1;
    NSUInteger numLargerSpaces = groups.count - 1;
    NSUInteger numSmallerSpaces = totalNumSpaces - numLargerSpaces;
    CGFloat avgLengthOfPadding = (widthToDrawIn*AVG_PERCENT_OF_PLACEHOLDER_FOR_PADDING)/totalNumSpaces;
    CNNumberEntryTextRedlining redlining;
    redlining.lengthOfPlaceholder = (widthToDrawIn - (avgLengthOfPadding * totalNumSpaces))/totalNumDigits;
    redlining.lengthOfLargerSpace = avgLengthOfPadding*(1.0 + LARGER_SPACE_RELATIVE_DELTA_TO_SMALLER);
    redlining.lengthOfSmallerSpace = ((avgLengthOfPadding*totalNumSpaces) - (redlining.lengthOfLargerSpace*numLargerSpaces))/numSmallerSpaces;
    redlining.sideMargin = (totalWidth - widthToDrawIn)/2.0;
    return redlining;
}

@end
