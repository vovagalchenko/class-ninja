//
//  CNSearchViewController.h
//  ClassNinja
//
//  Created by Boris Suvorov on 8/31/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CNSearchViewControllerDelegateProtocol <NSObject>
- (void)buildUIForSearchResults:(NSArray *)models;
@end

@interface CNSearchViewController : UIViewController
@property (nonatomic, weak) id <CNSearchViewControllerDelegateProtocol> searchDelegate;
@end
