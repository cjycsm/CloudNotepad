//
//  LoginViewController.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/4/28.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "LoginViewController.h"
#import "RegisterViewController.h"
#import "CloudAction.h"
#import "JGProgressHUD.h"
#import <BmobSDK/Bmob.h>

@interface LoginViewController ()<UITextFieldDelegate, JGProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"登录"];
    
    [_usernameTextField setDelegate:self];
    [_passwordTextField setDelegate:self];
    
    if(self.presentedViewController) {
        [self.presentedViewController removeFromParentViewController];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if([textField isEqual:_usernameTextField]) {
        [_passwordTextField becomeFirstResponder];
    }
    else if ([textField isEqual:_passwordTextField]) {
        [_passwordTextField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [_loginButton setEnabled:NO];
    [_loginButton setAlpha:0.6];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if([textField isEqual:_usernameTextField]) {
        if(textField.text.length - range.length + string.length >= 6 && _passwordTextField.text.length >= 6) {
            [_loginButton setEnabled:YES];
            [_loginButton setAlpha:1];
        }
        else {
            [_loginButton setEnabled:NO];
            [_loginButton setAlpha:0.6];
        }
    }
    else {
        if(textField.text.length - range.length + string.length >= 6 && _usernameTextField.text.length >= 6) {
            [_loginButton setEnabled:YES];
            [_loginButton setAlpha:1];
        }
        else {
            [_loginButton setEnabled:NO];
            [_loginButton setAlpha:0.6];
        }
    }

    return YES;
}

- (IBAction)goToRegisterVC:(id)sender {
    RegisterViewController *registerVC = [[RegisterViewController alloc] init];
    [self.navigationController pushViewController:registerVC animated:YES];
}

- (IBAction)loginAction:(id)sender {
    [_usernameTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
    
    [_loginButton setEnabled:NO];
    [_loginButton setAlpha:0.6];
    [_loginButton setTitle:@"登录中..." forState:UIControlStateNormal];
    
    [BmobUser loginWithUsernameInBackground:_usernameTextField.text password:_passwordTextField.text block:^(BmobUser *user, NSError *error) {
        if(user) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"onlyAutoInWLAN"];
                
            JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
            [HUD setDelegate:self];
            HUD.textLabel.text = @"登录成功";
            HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
            [HUD showInView:self.view];
            [HUD dismissAfterDelay:1.f];
                
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"canSync"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"isSync"]) {
                [CloudAction upload];
            }
        }
        else {
            [self.loginButton setEnabled:YES];
            [self.loginButton setAlpha:1];
            [self.loginButton setTitle:@"登录" forState:UIControlStateNormal];
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"登录失败" message:@"用户名或密码错误！" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

- (void)progressHUD:(JGProgressHUD *)progressHUD didDismissFromView:(UIView *)view {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
