//
//  CloudViewController.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/5/2.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "CloudViewController.h"
#import "CloudAction.h"
#import <BmobSDK/Bmob.h>

@interface CloudViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *titleArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation CloudViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:@"云同步"];
    
    [_usernameLabel setText:[NSString stringWithFormat:@"当前用户：%@", [BmobUser currentUser].username]];
    
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"isSync"]) {
        _titleArray = @[@"仅在连接无线网络时自动同步", @"正在同步数据..."];
    }
    else {
        _titleArray = @[@"仅在连接无线网络时自动同步", @"同步云端便签"];
    }
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncChange) name:@"startSync" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncChange) name:@"finishSync" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)syncChange {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"isSync"]) {
        _titleArray = @[@"仅在连接无线网络时自动同步", @"正在同步数据..."];
    }
    else {
        _titleArray = @[@"仅在连接无线网络时自动同步", @"同步云端便签"];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _titleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier =@"TableViewCell";
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:identifier];
    if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = _titleArray[indexPath.row];
    if(indexPath.row == 0) {
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        UISwitch *autoSwitch = [[UISwitch alloc] init];
        [autoSwitch setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"onlyAutoInWLAN"]];
        [autoSwitch addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell setAccessoryView:autoSwitch];
    }
    else if(indexPath.row == 1) {
        if([cell.textLabel.text isEqualToString:@"同步云端便签"]) {
            cell.textLabel.textColor = [UIColor colorWithRed:13 / 255.0 green:94 / 255.0 blue:250 / 255.0 alpha:1];
        }
        else {
            cell.textLabel.textColor = [UIColor lightGrayColor];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.row == 1) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if([cell.textLabel.text isEqualToString:@"同步云端便签"]) {
            [CloudAction upload];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSDate *lastUpdateTime = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"lastUpdateTimeFor%@", [BmobUser currentUser].username]];
    NSString *timeString;
    if(lastUpdateTime) {
        timeString = [_dateFormatter stringFromDate:lastUpdateTime];
    }
    else {
        timeString = @"尚未同步";
    }
    return [NSString stringWithFormat:@"最后同步时间：%@", timeString];
}

- (void)switchAction:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:@"onlyAutoInWLAN"];
}

- (IBAction)logoutAction:(id)sender {
    UIAlertController *logoutAlertController = [UIAlertController alertControllerWithTitle:nil message:@"退出登录后将无法使用云同步功能，你确定要继续吗？" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *logoutAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [BmobUser logout];
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [logoutAlertController addAction:cancelAction];
    [logoutAlertController addAction:logoutAction];
    [self presentViewController:logoutAlertController animated:YES completion:nil];
}

@end
