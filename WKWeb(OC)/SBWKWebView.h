
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SBWKDelegateController.h"

@class SBWKWebView;
@class SBScriptMessage;
@class SBWKWebViewConfig;

@protocol SBWKWebViewMessageHandleDelegate <NSObject>

@optional
- (void)qhb_webView:(nonnull SBWKWebView *)webView didReceiveScriptMessage:(nonnull SBScriptMessage *)message;

@end

@protocol SBWKWebViewDelegate <NSObject>
@optional
- (void)webView:(SBWKWebView *_Nullable)webview progressEstimateDidChange:(CGFloat)progress;
- (void)webView:(SBWKWebView *_Nullable)webview currentTitle:(NSString *_Nullable)title;
@end

@interface SBWKWebView : WKWebView<WKDelegate,SBWKWebViewMessageHandleDelegate>

@property(nullable, nonatomic, weak) id<SBWKWebViewDelegate> sbWebViewDelegate;
//webview加载的url地址
@property (nullable, nonatomic, copy) NSString *webViewRequestUrl;
//webview加载的参数
@property (nullable, nonatomic, copy) NSDictionary *webViewRequestParams;

@property (nullable, nonatomic, weak) id<SBWKWebViewMessageHandleDelegate> qhb_messageHandlerDelegate;

- (instancetype)initWithFrame:(CGRect)frame config:(SBWKWebViewConfig *)webConfig;

#pragma mark - Load Url

- (void)loadRequestWithRelativeUrl:(nonnull NSString *)relativeUrl;

- (void)loadRequestWithRelativeUrl:(nonnull NSString *)relativeUrl params:(nullable NSDictionary *)params;

/**
 *  加载本地HTML页面
 *
 *  @param htmlName html页面文件名称
 */
- (void)loadLocalHTMLWithFileName:(nonnull NSString *)htmlName;

#pragma mark - View Method

/**
 *  重新加载webview
 */
- (void)reloadWebView;

/**
 *  安全release
 */
- (void)safelyRelease;

#pragma mark - JS Method Invoke

/**
 *  调用JS方法（无返回值）
 *
 *  @param jsMethod JS方法名称
 */
- (void)callJS:(nonnull NSString *)jsMethod;

/**
 *  调用JS方法（可处理返回值）
 *
 *  @param jsMethod JS方法名称
 *  @param handler  回调block
 */
- (void)callJS:(nonnull NSString *)jsMethod handler:(nullable void(^)(__nullable id response))handler;

@end
