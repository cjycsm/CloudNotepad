//
//  SettingViewController.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/3/7.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "SettingViewController.h"
#import "LoginViewController.h"
#import "CloudViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <BmobSDK/Bmob.h>

@interface SettingViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *titleArray;

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:@"设置"];
    
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    
    _titleArray = @[@[@"云服务"], @[@"触控ID和密码"], @[@"分享时隐藏页头时间", @"分享时隐藏页脚来源"]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _titleArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ((NSArray *)_titleArray[section]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier =@"TableViewCell";
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:identifier];
    if(cell == nil) {
        if(indexPath.section == 0) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        }
        else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
    }
    cell.textLabel.text = _titleArray[indexPath.section][indexPath.row];
    if(indexPath.section == 0) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        NSString *userString;
        if([BmobUser currentUser]) {
            userString = [BmobUser currentUser].username;
        }
        else {
            userString = @"未登录";
        }
        cell.detailTextLabel.text = userString;
        cell.detailTextLabel.textColor = [UIColor colorWithRed:13 / 255.0 green:94 / 255.0 blue:250 / 255.0 alpha:1];
    }
    else {
        UISwitch *settingSwitch = [[UISwitch alloc] init];
        if(indexPath.section == 1) {
            [settingSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"useTouchID"]];
        }
        else if(indexPath.section == 2){
            if(indexPath.row == 0) {
                [settingSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"hideHeader"]];
            }
            else if(indexPath.row == 1) {
                [settingSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"hideFooter"]];
            }
        }
        [settingSwitch addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = settingSwitch;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 0) {
        if([BmobUser currentUser]) {
            CloudViewController *cloudVC = [[CloudViewController alloc] init];
            [cloudVC setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:cloudVC animated:YES];
        }
        else {
            LoginViewController *loginVC = [[LoginViewController alloc] init];
            [loginVC setHidesBottomBarWhenPushed:YES];
            [self.navigationController pushViewController:loginVC animated:YES];
        }
    }
}

- (void)switchAction:(UISwitch *)sender {
    UITableViewCell *cell = (UITableViewCell *)sender.superview;
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    if(indexPath.section == 1) {
        if(!sender.isOn) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"关闭后您将无法使用加密功能，所有便签都将处于未加密状态，您确定要关闭吗？" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                LAContext *context = [[LAContext alloc] init];
                if([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil]) {
                    [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"请验证指纹或输入密码以关闭加密功能。" reply:^(BOOL success, NSError * _Nullable error) {
                        if(success) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"useTouchID"];
                            }];
                        }
                        else {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [sender setOn:!sender.isOn];
                                [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"useTouchID"];
                            }];
                        }
                    }];
                }
                else {
                    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"useTouchID"];
                }
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [sender setOn:!sender.isOn];
                [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"useTouchID"];
            }];
            [alertController addAction:okAction];
            [alertController addAction:cancelAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        else {
            LAContext *context = [[LAContext alloc] init];
            if(![context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:nil]) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"开启失败" message:@"请确保在系统设置中已启用触控ID。" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [sender setOn:!sender.isOn];
                    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"useTouchID"];
                }];
                [alertController addAction:okAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }
            else {
                [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"useTouchID"];
            }
        }
    }
    else if(indexPath.section == 2) {
        if(indexPath.row == 0) {
            [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"hideHeader"];
        }
        else if (indexPath.row == 1) {
            [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"hideFooter"];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == 0) {
        return @"登录云服务账号后，可实现便签在多设备上的云同步功能。";
    }
    else if (section == 1) {
        return @"在系统设置中启用触控ID后，可开启实现便签的加密功能。";
    }
    else {
        return nil;
    }
}

@end
