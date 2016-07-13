//
//  RNNavigator.m
//  AAKitDemo
//
//  Created by HuangPeng on 7/11/16.
//  Copyright © 2016 Beacon. All rights reserved.
//

#import "RNNavigator.h"
#import "RNViewController.h"
#import <MJExtension.h>
#import "RNControllerManager.h"

typedef void (^RNTransitionCompletionBlock) (UIViewController *vc);
typedef void (^RNTransitionBlock) (RNTransitionCompletionBlock completion);

@implementation RNViewControllerFinder

- (UIViewController *)topViewController {
    return [self findTopVC:[[UIApplication sharedApplication].delegate window].rootViewController];
}

- (UIViewController *)findTopVC:(UIViewController *)vc {
    if (vc.presentedViewController) {
        return [self findTopVC:vc.presentedViewController];
    }
    
    if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self findTopVC:[(UITabBarController *)vc selectedViewController]];
    }
    
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self findTopVC:[(UINavigationController *)vc viewControllers].lastObject];
    }
    return vc;
}

- (UITabBarController *)tabBarController {
    UIViewController *vc = [[UIApplication sharedApplication].delegate window].rootViewController;
    if ([vc isKindOfClass:[UITabBarController class]]) {
        return (UITabBarController *)vc;
    }
    return nil;
}

@end

@implementation RNNavigationStyle

@end

@implementation RNNavigationContext

@end
               
@implementation RNNavigator {
    
}

static RCTBridge *rctBridge = nil;
+ (void)setRTCBridge:(RCTBridge *)bridge {
    rctBridge = bridge;
}

static id<RNViewControllerFinder> navigatorTopViewControllerFinder = nil;

+ (void)setTopViewControllerFinder:(id<RNViewControllerFinder>)topViewControllerFinder {
    navigatorTopViewControllerFinder = topViewControllerFinder;
}

- (id<RNViewControllerFinder>)controllerFinder {
    if (navigatorTopViewControllerFinder == nil) {
        navigatorTopViewControllerFinder = [RNViewControllerFinder new];
    }
    return navigatorTopViewControllerFinder;
}

- (UIViewController *)topVC {
    return [[self controllerFinder] topViewController];
}

- (UITabBarController *)tabBarController {
    return [[self controllerFinder] tabBarController];
}

static id<RNViewControllerFactory> navigatorControllerFactory = nil;
+ (void)setViewControllerFactory:(id<RNViewControllerFactory>)controlerFactory {
    navigatorControllerFactory = controlerFactory;
}

- (UIViewController *)activeController:(NSString *)controllerId {
    UIViewController *vc = [[RNControllerManager sharedManager] findController:controllerId];
    return vc ?: [[self controllerFinder] topViewController];
}

- (UIViewController *)controllerWithContext:(NSDictionary *)context {
    return [self controllerWithContext:context callback:nil];
}

- (UIViewController *)controllerWithContext:(NSDictionary *)context callback:(RCTResponseSenderBlock)callback {
    RNNavigationContext *naviContext = [RNNavigationContext mj_objectWithKeyValues:context];
    naviContext.callback = callback;
    
    if (naviContext.isNativeComponent) {
        NSAssert(navigatorControllerFactory != nil, @"you need to set navigationControllerFactory");
        UIViewController *vc = [navigatorControllerFactory controllerWithContext:naviContext];
        NSAssert(vc != nil, @"failed to create component: %@", naviContext.component);
        return vc;
    }
    else {
        if (naviContext.component) {
            NSAssert(rctBridge, @"please call [RNNavigator setRCTBridge]");
            return [[RNViewController alloc] initWithContext:naviContext bridge:rctBridge];
        }
        return nil;
    }
}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

static void didFinishTransitionTo(UIViewController *to, RCTResponseSenderBlock callback) {
    if (to) {
        NSString *controllerId = nil;
        if ([to isKindOfClass:[RNViewController class]]) {
            controllerId = [(RNViewController *)to rn_controllerId];
        }
        callback(@[ controllerId ?: @"" ]);
    }
    else {
        callback(@[]);
    }
}

RCT_EXPORT_METHOD(push:(NSDictionary *)context animated:(BOOL)animated completion:(RCTResponseSenderBlock)completion) {
    RNNavigationContext *naviContext = [RNNavigationContext mj_objectWithKeyValues:context];
    UIViewController *to = [self controllerWithContext:context];
    UIViewController *from = [self activeController:naviContext.controllerId];
    
    if (to && from.navigationController) {
        [from.navigationController pushViewController:to animated:animated];
        didFinishTransitionTo(to, completion);
    }
    else {
        NSLog(@"%@, %@, %@", to, from, from.navigationController);
        didFinishTransitionTo(nil,  completion);
    }
}

RCT_EXPORT_METHOD(present:(NSDictionary *)context animated:(BOOL)animated completion:(RCTResponseSenderBlock)completion) {
    RNNavigationContext *naviContext = [RNNavigationContext mj_objectWithKeyValues:context];
    UIViewController *to = [self controllerWithContext:context];
    UIViewController *from = [self activeController:naviContext.controllerId];
    
    if (from && to) {
        [from presentViewController:to animated:animated completion:^{
            didFinishTransitionTo(to, completion);
        }];
    }
    else {
        NSLog(@"%@, %@, %@", to, from);
        didFinishTransitionTo(nil, completion);
    }
}

// This is an exported method that is available in JS.
RCT_EXPORT_METHOD(pop:(NSDictionary *)context animated:(BOOL)animated completion:(RCTResponseSenderBlock)completion) {
    RNNavigationContext *naviContext = [RNNavigationContext mj_objectWithKeyValues:context];
    UIViewController *from = [self activeController:naviContext.controllerId];
    [from.navigationController popViewControllerAnimated:animated];
}

RCT_EXPORT_METHOD(dismiss:(NSDictionary *)context animated:(BOOL)animated completion:(RCTResponseSenderBlock)completion) {
    RNNavigationContext *naviContext = [RNNavigationContext mj_objectWithKeyValues:context];
    UIViewController *from = [self activeController:naviContext.controllerId];
    [from dismissViewControllerAnimated:animated completion:^{
        if (completion) {
            completion(@[]);
        }
    }];
}

RCT_EXPORT_METHOD(popToRoot:(NSDictionary *)context animated:(BOOL)animated completion:(RCTResponseSenderBlock)completion) {
    RNNavigationContext *naviContext = [RNNavigationContext mj_objectWithKeyValues:context];
    UIViewController *from = [self activeController:naviContext.controllerId];
    [from.navigationController popToRootViewControllerAnimated:animated];
}

RCT_EXPORT_METHOD(setTop:(NSDictionary *)context animated:(BOOL)animated completion:(RCTResponseSenderBlock)completion) {
    RNNavigationContext *naviContext = [RNNavigationContext mj_objectWithKeyValues:context];
    UIViewController *from = [self activeController:naviContext.controllerId];
    UIViewController *to = [self controllerWithContext:context];
    if (from.navigationController && to) {
        UINavigationController *nav = from.navigationController;
        NSMutableArray *vcs = [nav.viewControllers mutableCopy];
        if (vcs.count > 0) {
            vcs[vcs.count - 1] = to;
            [nav setViewControllers:vcs animated:animated];
        }
        else {
            [nav setViewControllers:@[to] animated:animated];
        }
        didFinishTransitionTo(to, completion);
    }
    else {
        didFinishTransitionTo(nil, completion);
    }
}

RCT_EXPORT_METHOD(setRoot:(NSDictionary *)context animated:(BOOL)animated completion:(RCTResponseSenderBlock)completion) {
    RNNavigationContext *naviContext = [RNNavigationContext mj_objectWithKeyValues:context];
    UIViewController *from = [self activeController:naviContext.controllerId];
    UIViewController *to = [self controllerWithContext:context];
    if (from.navigationController && to) {
        UINavigationController *nav = from.navigationController;
        [nav setViewControllers:@[to] animated:animated];
        didFinishTransitionTo(to, completion);
    }
    else {
        didFinishTransitionTo(nil, completion);
    }
}

RCT_EXPORT_METHOD(switchToTab:(NSInteger)tabIndex) {
    UITabBarController *tabController = [self tabBarController];
    if (tabIndex >= 0 && tabIndex < tabController.viewControllers.count) {
        if (tabIndex != tabController.selectedIndex) {
            tabController.selectedIndex = tabIndex;
        }
    }
    else {
        NSAssert(NO, @"tabIndex: %zi exceed range: 0-%zi", tabIndex, tabController.viewControllers.count);
    }
}

@end
