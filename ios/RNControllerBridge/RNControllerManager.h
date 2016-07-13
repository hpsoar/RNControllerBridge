//
//  RNControllerManager.h
//  RNControllerBridge
//
//  Created by HuangPeng on 7/13/16.
//  Copyright © 2016 Beacon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RNControllerManager : NSObject

+ (instancetype)sharedManager;

- (NSString *)registerController:(UIViewController *)controller;
- (void)unregisterController:(NSString *)controllerId;

@end
