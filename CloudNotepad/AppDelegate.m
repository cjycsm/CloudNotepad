//
//  AppDelegate.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/3/7.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeViewController.h"
#import "SettingViewController.h"
#import "LocalDatabase.h"
#import "Note.h"
#import "IQKeyboardManager.h"
#import "AFNetworking.h"
#import <UMCommon/UMCommon.h>
#import <UMShare/UMShare.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import <BmobSDK/Bmob.h>
#import "CloudAction.h"

@interface AppDelegate ()<UITabBarControllerDelegate>

@end

@implementation AppDelegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if([viewController isKindOfClass:UINavigationController.class]) {
        UIViewController *chileViewController = [((UINavigationController *)viewController).childViewControllers firstObject];
        if([chileViewController isKindOfClass:SettingViewController.class]) {
            UIViewController *homeViewController =  [[[[tabBarController childViewControllers] firstObject] childViewControllers] firstObject];
            if([homeViewController isKindOfClass:HomeViewController.class]) {
                [((HomeViewController *)homeViewController).searchController setActive:NO];
            }
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController.view setBackgroundColor:[UIColor whiteColor]];
    [tabBarController setDelegate:self];
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    UINavigationController *navigationVC1 = [[UINavigationController alloc] init];
    UINavigationController *navigationVC2 = [[UINavigationController alloc] init];
    [navigationVC1.tabBarItem setTitle:@"便签"];
    [navigationVC1.tabBarItem setImage:[UIImage imageNamed:@"document"]];
    [navigationVC1.tabBarItem setSelectedImage:[UIImage imageNamed:@"document_filled"]];
    [navigationVC2.tabBarItem setTitle:@"设置"];
    [navigationVC2.tabBarItem setImage:[UIImage imageNamed:@"setting"]];
    [navigationVC2.tabBarItem setSelectedImage:[UIImage imageNamed:@"setting_filled"]];
    [tabBarController addChildViewController:navigationVC1];
    [tabBarController addChildViewController:navigationVC2];

    HomeViewController *homeVC = [[HomeViewController alloc] init];
    SettingViewController *settingVC = [[SettingViewController alloc] init];
    [navigationVC1 addChildViewController:homeVC];
    [navigationVC2 addChildViewController:settingVC];
    
    
    IQKeyboardManager *keyboardManager = [IQKeyboardManager sharedManager];
    keyboardManager.enable = YES;
    keyboardManager.enableAutoToolbar = NO;
    keyboardManager.shouldResignOnTouchOutside =YES;
    
    [UMConfigure initWithAppkey:@"5adb2459f43e4861af0002cc" channel:nil];
    /*设置QQ平台的appID*/
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_QQ appKey:@"1106560852"  appSecret:nil redirectURL:@"http://mobile.umeng.com/social"];
    /* 设置新浪的appKey和appSecret */
    [[UMSocialManager defaultManager] setPlaform:UMSocialPlatformType_Sina appKey:@"2890354354"  appSecret:@"b65d30356bb5091fd2cac4b0a3237ee3" redirectURL:@"https://sns.whalecloud.com/sina2/callback"];
    
    [Bmob registerWithAppKey:@"88bbf6ba1508786d537dda39d29e6174"];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isSync"];

    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager startMonitoring];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"canSync"];
        if((status == AFNetworkReachabilityStatusReachableViaWiFi || (![[NSUserDefaults standardUserDefaults] boolForKey:@"onlyAutoInWLAN"] && status == AFNetworkReachabilityStatusReachableViaWWAN))) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"canSync"];
        }
        else {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"canSync"];
        }
    }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    LAContext *context = [[LAContext alloc] init];
    if(![context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"useTouchID"];
    }
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        if(![BmobUser currentUser]) {
            return;
        }
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"canSync"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"isSync"]) {
            [CloudAction upload];
        }
    });
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
