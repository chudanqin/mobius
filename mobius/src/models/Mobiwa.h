//
//  Mobiwa.h
//  mobius
//
//  Created by chudanqin on 09/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSInteger, MobiLoadOptions) {
    MobiLoadOptionsNil = 0,
    MobiLoadOptionParseKF7 = 1 << 0,
};

@interface Mobiwa : NSObject <NSCoding>

@property (nullable, nonatomic, copy) NSString *baseDir;

@property (nonnull, nonatomic, copy, readonly) NSString *lastDir;

@property (nonnull, nonatomic, copy, readonly) NSString *metaInfoLastPath;

@property (nonnull, nonatomic, copy, readonly) NSString *MIMETypeLastPath;

@property (nonnull, nonatomic, copy, readonly) NSArray<NSString *> *markupLastPaths;

@property (nonnull, nonatomic, copy, readonly) NSArray<NSString *> *flowLastPaths;

@property (nonnull, nonatomic, copy, readonly) NSArray<NSString *> *resourceLastPaths;

+ (nonnull instancetype)instanceWithMobiFileAtPath:(nonnull NSString *)mobiPath
                                 outputDir:(nullable NSString *)outputDir
                               loadOptions:(MobiLoadOptions)loadOptions;

+ (nonnull instancetype)loadFromPath:(NSString *)path;

- (BOOL)saveAtPath:(NSString *)path;

@end
