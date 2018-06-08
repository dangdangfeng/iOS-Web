
#import "SBWKWebView.h"
#import "SBScriptMessage.h"
#import "SBWKWebViewConfig.h"

//这里可以统一设置WebView的访问域名，方便切换
#ifdef DEBUG
#   define BASE_URL_API    @"http://****/"   //测试环境
#else
#   define BASE_URL_API    @"http://****/"   //正式环境
#endif

@interface SBWKWebView ()

@property (nonatomic, strong) NSURL *baseUrl;
@property (nonatomic, strong) WKUserContentController *userContentController;

@end

@implementation SBWKWebView

- (instancetype)initWithFrame:(CGRect)frame config:(SBWKWebViewConfig *)webConfig{
    WKWebViewConfiguration *configuration = [self injectWKWebViewConfiguration:webConfig];
    if (self = [super initWithFrame:frame configuration:configuration]) {
        self.baseUrl = [NSURL URLWithString:BASE_URL_API];
    }
    return self;
}

- (WKWebViewConfiguration * _Nonnull)injectWKWebViewConfiguration:(SBWKWebViewConfig *)webConfig {
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    WKPreferences *preference = [[WKPreferences alloc] init];
    preference.javaScriptEnabled = YES;
    configuration.preferences = preference;
    
    // 通过js与webview内容交互配置
    self.userContentController = configuration.userContentController;
    SBWKDelegateController * delegateController = [[SBWKDelegateController alloc]init];
    delegateController.delegate = self;
    [configuration.userContentController addScriptMessageHandler:delegateController name:@"webViewApp"];
    
    // 此处添加相关的JS交互
    for (NSString *handlerName in webConfig.scriptMessageHandlerArray) {
        [configuration.userContentController addScriptMessageHandler:delegateController name:handlerName];
    }
    
    for (WKUserScript *userScript in webConfig.userScriptArray) {
        [configuration.userContentController addUserScript:userScript];
    }
    
    //开启手势交互
    self.allowsBackForwardNavigationGestures = webConfig.isAllowsBackForwardGestures;
    
    //滚动条
    self.scrollView.showsVerticalScrollIndicator = webConfig.isShowVerticalScrollIndicator;
    self.scrollView.showsHorizontalScrollIndicator = webConfig.isShowHorizontalScrollIndicator;
    
    [self addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    
    return configuration;
}

#pragma mark - Load Url

- (void)loadRequestWithRelativeUrl:(NSString *)relativeUrl {
    
    [self loadRequestWithRelativeUrl:relativeUrl params:nil];
}

- (void)loadRequestWithRelativeUrl:(NSString *)relativeUrl params:(NSDictionary *)params {
    
    NSURL *url = [self generateURL:relativeUrl params:params];
    
    [self loadRequest:[NSURLRequest requestWithURL:url]];
}

/**
 *  加载本地HTML页面
 *
 *  @param htmlName html页面文件名称
 *
 */
- (void)loadLocalHTMLWithFileName:(nonnull NSString *)htmlName {

    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    NSString * htmlPath = [[NSBundle mainBundle] pathForResource:htmlName
                                                          ofType:@"html"];
    NSString * htmlCont = [NSString stringWithContentsOfFile:htmlPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    
    [self loadHTMLString:htmlCont baseURL:baseURL];
}

- (NSURL *)generateURL:(NSString*)baseURL params:(NSDictionary*)params {
    
    self.webViewRequestUrl = baseURL;
    self.webViewRequestParams = params;
    
    NSMutableDictionary *param = [NSMutableDictionary dictionaryWithDictionary:params];
    
    NSMutableArray* pairs = [NSMutableArray array];
    
    for (NSString* key in param.keyEnumerator) {
        NSString *value = [NSString stringWithFormat:@"%@",[param objectForKey:key]];

        NSString* escaped_value = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                              (__bridge CFStringRef)value,
                                                                              NULL,
                                                                              (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                              kCFStringEncodingUTF8);
        
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    
    NSString *query = [pairs componentsJoinedByString:@"&"];
    baseURL = [baseURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString* url = @"";
    if ([baseURL containsString:@"?"]) {
        url = [NSString stringWithFormat:@"%@&%@",baseURL, query];
    }
    else {
        url = [NSString stringWithFormat:@"%@?%@",baseURL, query];
    }
    //绝对地址
    if ([url.lowercaseString hasPrefix:@"http"]) {
        return [NSURL URLWithString:url];
    }
    else {
        return [NSURL URLWithString:url relativeToURL:self.baseUrl];
    }
}

/**
 *  重新加载webview
 */
- (void)reloadWebView {
    [self loadRequestWithRelativeUrl:self.webViewRequestUrl params:self.webViewRequestParams];
}

/**
 *  安全release
 */
- (void)safelyRelease {
    if ([[NSThread currentThread] isMainThread]) {
        self.UIDelegate = nil;
        self.navigationDelegate = nil;
        self.sbWebViewDelegate = nil;
        self.qhb_messageHandlerDelegate = nil;
        if(self.superview){
            [self removeFromSuperview];
        }
        [self stopLoading];
    }
    else{
        [self performSelectorOnMainThread:@selector(safelyRelease) withObject:nil waitUntilDone:NO];
    }
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (object == self) {
            CGFloat progress = self.estimatedProgress;
            if ([self.URL.scheme isEqualToString:@"file"] && ([self.URL.absoluteString hasSuffix:@"localpage_index.html"] || [self.URL.absoluteString hasSuffix:@"localpage_incognito_index.html"])) {
                progress = 1.0f;
            }
            if (_sbWebViewDelegate && [_sbWebViewDelegate respondsToSelector:@selector(webView:progressEstimateDidChange:)]) {
                [_sbWebViewDelegate webView:self progressEstimateDidChange:progress];
            }
        }
        else{
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else if ([keyPath isEqualToString:@"title"]){
        if (object == self) {
            if (_sbWebViewDelegate && [_sbWebViewDelegate respondsToSelector:@selector(webView:currentTitle:)]) {
                [_sbWebViewDelegate webView:self currentTitle:self.title];
            }
        }
        else{
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSLog(@"message:%@",message.body);
    if ([message.body isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *body = (NSDictionary *)message.body;
        
        SBScriptMessage *msg = [SBScriptMessage new];
        [msg setValuesForKeysWithDictionary:body];
        
        if (self.qhb_messageHandlerDelegate && [self.qhb_messageHandlerDelegate respondsToSelector:@selector(qhb_webView:didReceiveScriptMessage:)]) {
            [self.qhb_messageHandlerDelegate qhb_webView:self didReceiveScriptMessage:msg];
        }
    }
    
}

#pragma mark - JS

- (void)callJS:(NSString *)jsMethod {
    [self callJS:jsMethod handler:nil];
}

- (void)callJS:(NSString *)jsMethod handler:(void (^)(id _Nullable))handler {
    
    NSLog(@"call js:%@",jsMethod);
    [self evaluateJavaScript:jsMethod completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        if (handler) {
            handler(response);
        }
    }];
}

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"estimatedProgress"];
    [self removeObserver:self forKeyPath:@"title"];
    //这里需要注意，前面增加过的方法一定要remove掉。
    [_userContentController removeScriptMessageHandlerForName:@"webViewApp"];
}

@end
