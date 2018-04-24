//
//  ViewController.m
//  mobius
//
//  Created by chudanqin on 08/04/2018.
//  Copyright © 2018 chudanqin. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "Mobiwa.h"
#import "Monica.h"
#import "Teleprompter.h"
#import "ViewController.h"

@interface Teleprompter () <MonicaStory>
@end

@interface ViewController () <WKUIDelegate, WKNavigationDelegate, UIGestureRecognizerDelegate, MonicaDelegate>

@property (nonatomic) Mobiwa *mobiwa;

@property (nonatomic) Teleprompter *teleprompter;

@property (nonatomic, weak) IBOutlet WKWebView *webView;

@property (nonatomic, assign) NSUInteger currentChapter;

@property (nonatomic, copy) dispatch_block_t webViewCompletionTask;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self loadMobiwa];
    [self configWebView];
    [self loadCurrentChapter];
    
    [Monica sharedInstance].delegate = self;
    [[Monica sharedInstance] setSpeed:MonicaSpeakSpeedFast];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"TTS" style:UIBarButtonItemStylePlain target:self action:@selector(makeTTS)];
}

- (void)makeTTS {
    [_webView evaluateJavaScript:@"document.body.innerText" completionHandler:^(id result, NSError *error) {
        if (![result isKindOfClass:[NSString class]] || error) {
            NSLog(@"failed to get text: %@, %@", result, error);
            return;
        }
        [self startTTS:result];
    }];
}

- (void)startTTS:(NSString *)text {
    if (_teleprompter == nil) {
        _teleprompter = [[Teleprompter alloc] init];
    }
    _teleprompter.text = text;
    [[Monica sharedInstance] tellStory:_teleprompter];
}

- (void)loadMobiwa {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *mobiwa_path = [dir stringByAppendingPathComponent:@"mobiwa_0"];
    Mobiwa *mobiwa = [Mobiwa loadFromPath:mobiwa_path];
    if (mobiwa == nil) {
        NSString *outputDir = [dir stringByAppendingPathComponent:@"0_epub"];
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:outputDir error:&error]) {
            NSLog(@"remove directory (%@) failed: %@", outputDir, error);
        }
        if (![[NSFileManager defaultManager] createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"create directory (%@) failed: %@", outputDir, error);
        } else {
            NSString *p0 = [[NSBundle mainBundle] pathForResource:@"0" ofType:@"azw3"];
            mobiwa = [Mobiwa instanceWithMobiFileAtPath:p0 outputDir:outputDir loadOptions:MobiLoadOptionsNil];
            if (mobiwa == nil || ![mobiwa saveAtPath:mobiwa_path]) {
                NSLog(@"archive mobiwa failed: %@", mobiwa_path);
            }
        }
    }
    _mobiwa = mobiwa;
}

- (void)configWebView {
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    
    NSString *jsString = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"meta" ofType:@"js"] encoding:NSUTF8StringEncoding error:NULL];

    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    [_webView.configuration.userContentController addUserScript:userScript];
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapWebView:)];
    tgr.delegate = self;
    [_webView addGestureRecognizer:tgr];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)tapWebView:(UITapGestureRecognizer *)tgr {
    CGPoint pt = [tgr locationInView:_webView];
    CGRect rect = _webView.bounds;
    if (pt.x < rect.size.width / 3) {
        if ([self hasPreviousChapter]) {
            [self loadContentAtChapter:(_currentChapter - 1)];
        }
    } else if (pt.x > (rect.size.width / 3 * 2)) {
        if ([self hasNextChapter]) {
            [self loadContentAtChapter:(_currentChapter + 1)];
        }
    }
}

- (BOOL)hasPreviousChapter {
    return _currentChapter > 0;
}

- (BOOL)hasNextChapter {
    return _currentChapter < (_mobiwa.markupLastPaths.count - 1);
}

- (void)saveCurrentChapter {
    [[NSUserDefaults standardUserDefaults] setObject:@(_currentChapter) forKey:_mobiwa.baseDir];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadCurrentChapter {
    _currentChapter = NSNotFound;
    if (_mobiwa != nil) {
        NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:_mobiwa.baseDir];
        [self loadContentAtChapter:[n unsignedIntegerValue]];
    }
}

- (void)loadContentAtChapter:(NSUInteger)chapter {
    if (chapter == _currentChapter) {
        return;
    }
    _currentChapter = chapter;
    [self saveCurrentChapter];
    NSCParameterAssert(chapter < _mobiwa.markupLastPaths.count);
    NSString *baseDir = _mobiwa.baseDir;
    NSString *markupPath = [baseDir stringByAppendingPathComponent:_mobiwa.markupLastPaths[chapter]];
    NSURL *epubURL = [NSURL fileURLWithPath:markupPath];
    NSURL *baseURL = [NSURL fileURLWithPath:[markupPath stringByDeletingLastPathComponent]];
//    [_webView loadFileURL:epubURL allowingReadAccessToURL:baseURL];
    //    [_webView loadRequest:[NSURLRequest requestWithURL:epubURL]];
    NSString *htmlString = [NSString stringWithContentsOfURL:epubURL encoding:NSUTF8StringEncoding error:NULL];
    [_webView loadHTMLString:htmlString baseURL:baseURL];
}

- (void)monicaDidFinishTellingStory:(Monica *)monica {
    if ([self hasNextChapter]) {
        typeof (self) __weak weakSelf = self;
        _webViewCompletionTask = ^{
            [weakSelf makeTTS];
        };
        [self loadContentAtChapter:(_currentChapter + 1)];
    }
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    return _webView;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (_webViewCompletionTask != nil) {
        _webViewCompletionTask();
        _webViewCompletionTask = nil;
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"webview did fail navigation: %@", error);
}

@end
