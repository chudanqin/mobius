//
//  Teleprompter.m
//  mobius
//
//  Created by chudanqin on 20/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#import "Teleprompter.h"

@interface Teleprompter ()

@property (nonatomic) NSRegularExpression *regex;

@property (nonatomic) NSCharacterSet *delimeterCharacterSet;

@end

@implementation Teleprompter

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setDelimeters:@[]];
    }
    return self;
}

- (void)setDelimeters:(NSArray<NSString *> *)delimeters {
    if (delimeters.count == 0) {
        delimeters = @[@"。", @"？", @"！", @".", @"?", @"!", @"\n"];
    }
    _delimeters = [delimeters copy];
    _delimeterCharacterSet = [NSCharacterSet characterSetWithCharactersInString:[delimeters componentsJoinedByString:@""]];
}

- (void)setText:(NSString *)text {
    _text = [text copy];
    _offset = 0;
}

- (NSString *)nextWords {
    NSString *ret = nil;
    do {
        NSUInteger len = _text.length;
        if (_offset >= len) {
            return nil;
        }
        NSRange range = [_text rangeOfCharacterFromSet:_delimeterCharacterSet options:kNilOptions range:NSMakeRange(_offset, len - _offset)];
        if (range.length == 0) {
            return nil;
        }
        ret = [_text substringWithRange:NSMakeRange(_offset, range.location - _offset)];
            
        _offset = NSMaxRange(range);
    } while ([ret length] == 0);
    return ret;
}

@end
