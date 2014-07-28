//
//  UITableView+LayoutSubviews.m
//  ClassNinja
//
//  Created by Vova Galchenko on 7/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "UITableView+LayoutSubviews.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UITableView (LayoutSubviews)

+ (void)load
{
    Method existing = class_getInstanceMethod(self, @selector(layoutSubviews));
    Method new = class_getInstanceMethod(self, @selector(_autolayout_replacementLayoutSubviews));
    
    method_exchangeImplementations(existing, new);
}

- (void)_autolayout_replacementLayoutSubviews
{
    [self _autolayout_replacementLayoutSubviews]; // not recursive due to method swizzling
    [super layoutSubviews];
}

@end
