//
//  Teleprompter.h
//  mobius
//
//  Created by chudanqin on 20/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Teleprompter : NSObject

@property (nullable, nonatomic, copy) NSString *text;

@property (nonnull, nonatomic, copy) NSArray<NSString *> *delimeters; // .。?？!！

@property (nonatomic, readonly) NSUInteger offset;

- (nullable NSString *)nextWords;

@end
