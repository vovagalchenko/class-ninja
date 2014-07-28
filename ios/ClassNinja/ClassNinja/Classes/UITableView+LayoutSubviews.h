//
//  UITableView+LayoutSubviews.h
//  ClassNinja
//
//  Created by Vova Galchenko on 7/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>

// Amazingly, UITableView's layoutSubviews doesn't call super's layoutSubviews,
// breaking constraints based layout for tableView. This category is to fix that.
@interface UITableView (LayoutSubviews)

@end
