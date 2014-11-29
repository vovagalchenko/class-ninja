//
//  CNFirstPageViewController.h
//  ClassNinja
//
//  Created by Boris Suvorov on 11/15/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import <Foundation/Foundation.h>

// Alternatively I could call it Siongs TDB (Title, Description, Button), but ternary sounds cool
@interface CNSiongsTernaryViewController : UIViewController

@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, readonly) UILabel *descriptionLabel;
@property (nonatomic, readonly) UIButton *button;

@property (nonatomic, copy) dispatch_block_t completionBlock;

@end

@interface CNConfirmationViewController : CNSiongsTernaryViewController
@end

@interface CNFirstPageViewController : CNSiongsTernaryViewController
- (instancetype)init;
@end
