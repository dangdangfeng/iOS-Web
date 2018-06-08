
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@protocol WKDelegate <NSObject>

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end

@interface SBWKDelegateController : UIViewController<WKScriptMessageHandler>

@property (weak , nonatomic) id<WKDelegate> delegate;

@end
