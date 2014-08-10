//
//  AppearanceConstants.h
//  ClassNinja
//
//  Created by Vova Galchenko on 7/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#ifndef ClassNinja_AppearanceConstants_h
#define ClassNinja_AppearanceConstants_h

#define HORIZONTAL_MARGIN       20.0
#define VERTICAL_MARGIN         50.0
#define INTER_ELEMENT_VERTICAL_PADDING      10.0

#define ANIMATION_DURATION      0.2

#define AUTH_BLUE_COLOR         [UIColor colorWithRed:17.0/255.0 green:33.0/255.0 blue:83.0/255.0 alpha:1.0]
#define WELCOME_BLUE_COLOR      [UIColor colorWithRed:27.0/255.0 green:127.0/255.0 blue:247.0/255.0 alpha:1.0]

#define FOCAL_LABEL_TEXT_SIZE   30
#define INSTRUCTION_LABEL_FONT  [UIFont cnSystemFontOfSize:18.0]

#define ASSERT_MAIN_THREAD()        NSAssert([[NSThread currentThread] isMainThread], @"<%@:%d> This must be executed on the main thread.",\
[[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__)
#define SIONG_NAVIGATION_CONTROLLER_BACKGROUND_COLOR ([UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0])

#endif
