//
//  AppearanceConstants.h
//  ClassNinja
//
//  Created by Vova Galchenko on 7/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#ifndef ClassNinja_AppearanceConstants_h
#define ClassNinja_AppearanceConstants_h

#define HORIZONTAL_MARGIN           15.0
#define VERTICAL_MARGIN             10.0
#define X_BUTTON_VERTICAL_MARGIN    25.0
#define CLOSE_BUTTON_DIMENSION      11.0
#define INTER_ELEMENT_VERTICAL_PADDING      10.0

#define CLOSE_BUTTON_OFFSET_X       17
#define CLOSE_BUTTON_OFFSET_Y       17

#define ANIMATION_DURATION      0.2

#define AUTH_BLUE_COLOR         [UIColor colorWithRed:17.0/255.0 green:33.0/255.0 blue:83.0/255.0 alpha:1.0]
#define WELCOME_BLUE_COLOR      [UIColor colorWithRed:27.0/255.0 green:127.0/255.0 blue:247.0/255.0 alpha:1.0]
#define DISABLED_GRAY_COLOR     [UIColor colorWithRed:116.0/255.0 green:125.0/255.0 blue:132.0/255.0 alpha:1.0]
#define CONFIRMATION_COLOR      [UIColor colorWithRed:47.0/255.0 green:198.0/255.0 blue:183.0/255.0 alpha:1.0]
#define DARK_CLOSE_BUTTON_COLOR [UIColor colorWithRed:32.0/255.0 green:28.0/255.0 blue:66.0/255.0 alpha:1.0]

#define DARK_GRAY_TEXT_COLOR    [UIColor colorWithRed:121/255.0 green:121/255.0 blue:121/255.0 alpha:1]
#define LIGHT_GRAY_TEXT_COLOR   [UIColor colorWithRed:185/255.0 green:185/255.0 blue:185/255.0 alpha:1]

#define FOCAL_LABEL_TEXT_SIZE   30
#define INSTRUCTION_LABEL_FONT  [UIFont cnSystemFontOfSize:18.0]

#define ASSERT_MAIN_THREAD()        CNAssert([[NSThread currentThread] isMainThread], @"main_thread", @"<%@:%d> This must be executed on the main thread.",\
[[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__)
#define SIONG_NAVIGATION_CONTROLLER_BACKGROUND_COLOR ([UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0])
#define QUESTION_TITLE_BACKGROUND_COLOR [UIColor colorWithRed:16/255.0 green:77/255.0 blue:147/255.0 alpha:1.0]
#define SEARCH_BACKGROUND_COLOR QUESTION_TITLE_BACKGROUND_COLOR

#define TAPPABLE_AREA_DIMENSION     44.0

static inline void configureStaticAppearance()
{
    UIFont *headerFooterFont = [UIFont cnBoldSystemFontOfSize:12.0];
    UILabel *appearanceOfLabelInsideTableHeader = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil];
    appearanceOfLabelInsideTableHeader.font = headerFooterFont;
    appearanceOfLabelInsideTableHeader.textColor = DARK_GRAY_TEXT_COLOR;
}

#endif
