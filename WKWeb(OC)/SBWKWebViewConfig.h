//
//  SBWKWebViewConfig.h
//  Test
//
//  Created by taoxiaofei on 2018/6/8.
//  Copyright © 2018年 xxx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface SBWKWebViewConfig : NSObject

/// WKScriptMessageHandler
/// 添加一个名称，就可以在JS通过这个名称发送消息：valueName自定义名字
/// window.webkit.messageHandlers.valueName.postMessage({body: 'xxx'})
@property (nonatomic, strong) NSArray<NSString *> *scriptMessageHandlerArray;

/// 动态加载并运行JS代码
@property (nonatomic, strong) NSArray<WKUserScript *> *userScriptArray;

/// 默认最小字体字体
@property (nonatomic, assign) CGFloat minFontSize;

/// 显示滚动条
@property (nonatomic, assign) BOOL isShowVerticalScrollIndicator;
@property (nonatomic, assign) BOOL isShowHorizontalScrollIndicator;

/// 开启手势交互
@property (nonatomic, assign) BOOL isAllowsBackForwardGestures;

/// 是否允许加载javaScript
@property (nonatomic, assign) BOOL isjavaScriptEnabled;

/// 是否允许JS自动打开窗口的，必须通过用户交互才能打开
@property (nonatomic, assign) BOOL isAutomaticallyJavaScript;

@end
