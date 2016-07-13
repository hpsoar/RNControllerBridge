//
//  RNControllerManager.m
//  RNControllerBridge
//
//  Created by HuangPeng on 7/13/16.
//  Copyright © 2016 Beacon. All rights reserved.
//

#import "RNControllerManager.h"

@implementation RNControllerManager {
    NSMutableDictionary *_controllerMap;
}

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static RNControllerManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [self new];
    });
    return manager;
}

static NSMutableDictionary* NICreateNonRetainingMutableDictionary(void) {
    return (__bridge_transfer NSMutableDictionary *)CFDictionaryCreateMutable(nil, 0, nil, nil);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _controllerMap = NICreateNonRetainingMutableDictionary();
    }
    return self;
}

- (NSString *)registerController:(UIViewController *)controller {
    NSString *controllerId = [self generateControllerId];
    _controllerMap[controllerId] = controller;
    return controllerId;
}

- (void)unregisterController:(NSString *)controllerId {
    [_controllerMap removeObjectForKey:controllerId];
}

- (UIViewController *)findController:(NSString *)controllerId {
    return _controllerMap[controllerId];
}

- (NSString *)generateControllerId {
    @synchronized (self) {
        static NSInteger seed = 0;
        seed += 1;
        return [NSString stringWithFormat:@"%zi", seed];
    }
}

@end
