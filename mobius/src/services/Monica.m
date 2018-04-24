//
//  Monica.m
//  mobius
//
//  Created by chudanqin on 20/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#import "BDSSpeechSynthesizer.h"
#import "Monica.h"

@interface Monica () <BDSSpeechSynthesizerDelegate>

@property (nonatomic) id<MonicaStory> currentStory;

@end

@implementation Monica

static Monica *instance;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *err = nil;
        // 在这里选择不同的离线音库（请在XCode中Add相应的资源文件），同一时间只能load一个离线音库。根据网络状况和配置，SDK可能会自动切换到离线合成。
        NSString *offlineEngineSpeechData = [[NSBundle mainBundle] pathForResource:@"Chinese_And_English_Speech_Female" ofType:@"dat"];
        
        NSString *offlineChineseAndEnglishTextData = [[NSBundle mainBundle] pathForResource:@"Chinese_And_English_Text" ofType:@"dat"];
        
        err = [[BDSSpeechSynthesizer sharedInstance] loadOfflineEngine:offlineChineseAndEnglishTextData speechDataPath:offlineEngineSpeechData licenseFilePath:nil withAppCode:@"10869575"];
        if (err) {
            NSLog(@"init BDSDK failed: %@", err);
        }
        [BDSSpeechSynthesizer setLogLevel:BDS_PUBLIC_LOG_INFO];
        instance = [Monica new];
        [[BDSSpeechSynthesizer sharedInstance] setSynthesizerDelegate:instance];
    });
    return instance;
}

- (void)hibernate {
    [BDSSpeechSynthesizer releaseInstance];
    instance = nil;
}

- (void)setSpeed:(MonicaSpeakSpeed)speed {
    [[BDSSpeechSynthesizer sharedInstance] setSynthParam:@(speed) forKey:BDS_SYNTHESIZER_PARAM_SPEED];
}

- (BOOL)tellStory:(id<MonicaStory>)story {
    _currentStory = story;
    [[BDSSpeechSynthesizer sharedInstance] cancel];
    return [self _tellPartOfStory];
}

- (BOOL)_tellPartOfStory {
    NSString *words = [_currentStory nextWords];
    if (words != nil) {
        NSError *error;
        [[BDSSpeechSynthesizer sharedInstance] speakSentence:words withError:&error];
        return error == nil;
    } else {
        [_delegate monicaDidFinishTellingStory:self];
        return YES;
    }
}

#pragma mark - delegate

- (void)synthesizerStartWorkingSentence:(NSInteger)SynthesizeSentence {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)synthesizerFinishWorkingSentence:(NSInteger)SynthesizeSentence {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)synthesizerSpeechStartSentence:(NSInteger)SpeakSentence {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)synthesizerSpeechEndSentence:(NSInteger)SpeakSentence {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self _tellPartOfStory];
}

- (void)synthesizerNewDataArrived:(NSData *)newData
                       DataFormat:(BDSAudioFormat)fmt
                   characterCount:(int)newLength
                   sentenceNumber:(NSInteger)SynthesizeSentence {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)synthesizerTextSpeakLengthChanged:(int)newLength
                           sentenceNumber:(NSInteger)SpeakSentence {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)synthesizerdidPause {
    
}

- (void)synthesizerResumed {
    
}

- (void)synthesizerErrorOccurred:(NSError *)error
                        speaking:(NSInteger)SpeakSentence
                    synthesizing:(NSInteger)SynthesizeSentence {
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)synthesizerCanceled {
    
}

@end
