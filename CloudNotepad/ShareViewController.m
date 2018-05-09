//
//  ShareViewController.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/4/20.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "ShareViewController.h"
#import "JGProgressHUD.h"
#import <UShareUI/UShareUI.h>

@interface ShareViewController ()

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *footerLabel;
@property (weak, nonatomic) IBOutlet UIImageView *shareImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *shareImageViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *headerDistance;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *footerDistance;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation ShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIColor *bgColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    [self.view setBackgroundColor:bgColor];
    
    UIBarButtonItem *saveButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save"] style:UIBarButtonItemStylePlain target:self action:@selector(saveImg)];
    UIBarButtonItem *socialButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"social"] style:UIBarButtonItemStylePlain target:self action:@selector(socialAction)];

    [self.navigationItem setRightBarButtonItems:@[socialButtonItem, saveButtonItem]];
    [self.navigationItem setTitle:@"分享预览"];
    
    _shareImageViewHeight.constant = _shareImage.size.height / _shareImage.size.width * _shareImageView.bounds.size.width;
    
    _backView.layer.shadowColor=[[UIColor blackColor] colorWithAlphaComponent:0.8].CGColor;
    _backView.layer.shadowOffset=CGSizeMake(5,5);
    _backView.layer.shadowOpacity=0.5;
    _backView.layer.shadowRadius=5;
    [_shareImageView setImage:_shareImage];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    _timeLabel.text = [_dateFormatter stringFromDate:_time];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"hideHeader"]) {
        [_timeLabel setHidden:YES];
        [_headerDistance setConstant:40.f];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"hideFooter"]) {
        [_footerLabel setHidden:YES];
        [_footerDistance setConstant:40.f];
    }
}

- (void)saveImg {
    CGSize s = _backView.bounds.size;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    [_backView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)socialAction {
    [UMSocialUIManager setPreDefinePlatforms:@[@(UMSocialPlatformType_QQ),@(UMSocialPlatformType_Tim),  @(UMSocialPlatformType_Qzone), @(UMSocialPlatformType_Sina)]];
    [UMSocialShareUIConfig shareInstance];
    [UMSocialUIManager showShareMenuViewInWindowWithPlatformSelectionBlock:^(UMSocialPlatformType platformType, NSDictionary *userInfo) {
        UMSocialMessageObject *messageObject = [UMSocialMessageObject messageObject];
        UMShareImageObject *shareObject = [[UMShareImageObject alloc] init];
        CGSize s = self.backView.bounds.size;
        // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
        UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
        [self.backView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [shareObject setShareImage:image];
        messageObject.shareObject = shareObject;
        [[UMSocialManager defaultManager] shareToPlatform:platformType messageObject:messageObject currentViewController:self completion:nil];
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if(error) {
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        HUD.textLabel.text = @"保存失败";
        HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
        [HUD showInView:self.view];
        [HUD dismissAfterDelay:2.0];
    }
    else {
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        HUD.textLabel.text = @"保存成功";
        HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
        [HUD showInView:self.view];
        [HUD dismissAfterDelay:2.0];
    }
}

@end
