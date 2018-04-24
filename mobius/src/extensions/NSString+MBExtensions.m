//
//  NSString+MBExtensions.m
//  mobius
//
//  Created by chudanqin on 19/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "NSString+MBExtensions.h"

@implementation NSString (MBExtensions)

- (NSString *)MD5 {
    if (self.length == 0) {
        return nil;
    }
    
    const char *value = [self UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count<CC_MD5_DIGEST_LENGTH; count++){
        [result appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return result;
}

@end
