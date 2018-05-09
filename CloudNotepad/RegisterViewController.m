//
//  RegisterViewController.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/5/1.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "RegisterViewController.h"
#import "JGProgressHUD.h"
#import <BmobSDK/Bmob.h>

@interface RegisterViewController ()<UITextFieldDelegate, JGProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordAgainTextField;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"注册"];
    [_usernameTextField setDelegate:self];
    [_passwordTextField setDelegate:self];
    [_passwordAgainTextField setDelegate:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if([textField isEqual:_usernameTextField]) {
        [_passwordTextField becomeFirstResponder];
    }
    else if([textField isEqual:_passwordTextField]) {
        [_passwordAgainTextField becomeFirstResponder];
    }
    else if ([textField isEqual:_passwordAgainTextField]) {
        [_passwordAgainTextField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [_registerButton setEnabled:NO];
    [_registerButton setAlpha:0.6];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if(textField.text.length - range.length + string.length > 20) {
        return NO;
    }
    else {
        if([textField isEqual:_usernameTextField]) {
            if(textField.text.length - range.length + string.length >= 6 && _passwordTextField.text.length >= 6 && _passwordAgainTextField.text.length >= 6) {
                [_registerButton setEnabled:YES];
                [_registerButton setAlpha:1];
            }
            else {
                [_registerButton setEnabled:NO];
                [_registerButton setAlpha:0.6];
            }
        }
        else if([textField isEqual:_passwordTextField]) {
            if(textField.text.length - range.length + string.length >= 6 && _usernameTextField.text.length >= 6 && _passwordAgainTextField.text.length >= 6) {
                [_registerButton setEnabled:YES];
                [_registerButton setAlpha:1];
            }
            else {
                [_registerButton setEnabled:NO];
                [_registerButton setAlpha:0.6];
            }
        }
        else if([textField isEqual:_passwordAgainTextField]) {
            if(textField.text.length - range.length + string.length >= 6 && _usernameTextField.text.length >= 6 && _passwordTextField.text.length >= 6) {
                [_registerButton setEnabled:YES];
                [_registerButton setAlpha:1];
            }
            else {
                [_registerButton setEnabled:NO];
                [_registerButton setAlpha:0.6];
            }
        }
        return YES;
    }
}

- (IBAction)registerAction:(id)sender {
    [_usernameTextField resignFirstResponder];
    [_passwordTextField resignFirstResponder];
    [_passwordAgainTextField resignFirstResponder];
    
    [_registerButton setEnabled:NO];
    [_registerButton setAlpha:0.6];
    [_registerButton setTitle:@"注册中..." forState:UIControlStateNormal];
    
    BOOL chFlag = false;
    for(int i = 0; i < _usernameTextField.text.length; i++) {
        unichar c = [_usernameTextField.text characterAtIndex:i];
        if(c < '0' && c > '9' && c < 'A' && c > 'Z' && c <'a' && c >'z') {
            chFlag = true;
            break;
        }
    }
    if(chFlag) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"注册失败" message:@"用户名只能包含字母或数字！" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:^{
            [self.registerButton setEnabled:YES];
            [self.registerButton setAlpha:1];
            [self.registerButton setTitle:@"注册" forState:UIControlStateNormal];

        }];
    }
    else if(![_passwordTextField.text isEqualToString:_passwordAgainTextField.text]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"注册失败" message:@"两次密码输入不一致！" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:^{
            [self.registerButton setEnabled:YES];
            [self.registerButton setAlpha:1];
            [self.registerButton setTitle:@"注册" forState:UIControlStateNormal];
        }];
    }
    else {
        BmobUser *bUser = [[BmobUser alloc] init];
        [bUser setUsername:_usernameTextField.text];
        [bUser setPassword:_passwordTextField.text];
        [bUser signUpInBackgroundWithBlock:^(BOOL isSuccessful, NSError *error) {
            [self.registerButton setEnabled:YES];
            [self.registerButton setAlpha:1];
            [self.registerButton setTitle:@"注册" forState:UIControlStateNormal];
            if(isSuccessful) {
                JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
                [HUD setDelegate:self];
                HUD.textLabel.text = @"注册成功";
                HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
                [HUD showInView:self.view];
                [HUD dismissAfterDelay:1.f];
            }
            else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"注册失败" message:@"用户名已存在，请尝试使用其他用户名。" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }];
    }
}

- (void)progressHUD:(JGProgressHUD *)progressHUD didDismissFromView:(UIView *)view {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
