#import "SceneDelegate.h"
#import <objc/message.h>

// The whole lab UI lives in LiquidGlassLabRoot.swift. Its entry point is the
// Objective-C class method +[LiquidGlassRootFactory makeRootViewController],
// looked up at run time so no generated Swift header is needed.
static UIViewController *LGLMakeRootViewController(void) {
    Class factory = NSClassFromString(@"LiquidGlassRootFactory");
    SEL selector = NSSelectorFromString(@"makeRootViewController");
    if (factory && [factory respondsToSelector:selector]) {
        UIViewController *root = ((UIViewController *(*)(id, SEL))objc_msgSend)(factory, selector);
        if (root) return root;
    }

    UIViewController *fallback = [UIViewController new];
    fallback.view.backgroundColor = UIColor.blackColor;
    UILabel *label = [UILabel new];
    label.text = @"LiquidGlassRootFactory 未找到：Swift 部分没有编进 App";
    label.textColor = UIColor.whiteColor;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [fallback.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:fallback.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:fallback.view.centerYAnchor],
        [label.widthAnchor constraintLessThanOrEqualToAnchor:fallback.view.widthAnchor constant:-40],
    ]];
    return fallback;
}

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:UIWindowScene.class]) return;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    window.backgroundColor = UIColor.blackColor;
    window.rootViewController = LGLMakeRootViewController();
    self.window = window;
    [window makeKeyAndVisible];
}

@end
