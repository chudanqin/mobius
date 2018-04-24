//
//  Monica.h
//  mobius
//
//  Created by chudanqin on 20/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MonicaStory

- (NSString *)nextWords;

@end

typedef NS_ENUM(NSInteger, MonicaSpeakSpeed) {
    MonicaSpeakSpeedSlow = 0,
    MonicaSpeakSpeedMedium = 5,
    MonicaSpeakSpeedFast = 9,
};

#define MONICA  [Monica sharedInstance]

@class Monica;

@protocol MonicaDelegate

- (void)monicaDidFinishTellingStory:(Monica *)monica;

@end

@interface Monica : NSObject

@property (nonatomic, weak) id<MonicaDelegate> delegate;

+ (instancetype)sharedInstance;

- (void)hibernate;

- (void)setSpeed:(MonicaSpeakSpeed)speed;

- (BOOL)tellStory:(id<MonicaStory>)story;

@end
