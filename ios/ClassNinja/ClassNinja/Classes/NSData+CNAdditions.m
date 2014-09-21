//
//  NSData+CNAdditions.m
//  ClassNinja
//
//  Created by Vova Galchenko on 9/21/14.
//  Copyright (c) 2014 Bova. All rights reserved.
//

#import "NSData+CNAdditions.h"

@implementation NSData (CNAdditions)

- (NSString *)hexString
{
    NSMutableString *tokenString = [NSMutableString stringWithCapacity:self.length*2];
    const unsigned char *bytes = self.bytes;
    for (int i = 0; i < self.length; i++) {
        [tokenString appendFormat:@"%02x", bytes[i]];
    }
    return [NSString stringWithString:tokenString];
}

@end
