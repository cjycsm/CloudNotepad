//
//  HomeViewController.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/3/7.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import <LocalAuthentication/LocalAuthentication.h>
#import "HomeViewController.h"
#import "TextViewController.h"
#import "Note.h"
#import "LocalDatabase.h"
#import "NoteTableViewCell.h"

@interface HomeViewController ()<UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UILabel *tineLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tineImageView;
@property (weak, nonatomic) IBOutlet UITableView *noteTableView;
@property (strong, nonatomic) NSMutableArray *noteArray;
@property (strong, nonatomic) NSMutableArray *searchArray;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     
    [self.navigationItem setTitle:@"便签"];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"] style:UIBarButtonItemStylePlain target:self action:@selector(goToNewTextVC)] animated:YES];
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    [_searchController setSearchResultsUpdater:self];
    [_searchController setDimsBackgroundDuringPresentation:NO];
    [_searchController setHidesNavigationBarDuringPresentation:NO];
    [_searchController.searchBar setDelegate:self];
    if (@available(iOS 11.0, *)) {
        [self.navigationItem setSearchController:_searchController];
        [self.navigationItem setHidesSearchBarWhenScrolling:NO];
    } else {
        // Fallback on earlier versions
        [_noteTableView setTableHeaderView:_searchController.searchBar];
    }
    
    [_noteTableView setDelegate:self];
    [_noteTableView setDataSource:self];
    [_noteTableView setScrollsToTop:YES];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm EEEE"];
    
    _searchArray = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncChange) name:@"finishSync" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_searchController.searchBar setHidden:NO];
    
    _noteArray = [[LocalDatabase sharedDatebase] getNoDeletedNote];
    if(_noteArray.count == 0) {
        [_tineLabel setHidden:NO];
        [_tineImageView setHidden:NO];
    }
    else {
        [_tineLabel setHidden:YES];
        [_tineImageView setHidden:YES];
    }
    [self refreshSearchArray];
    [_noteTableView reloadData];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [_searchController.searchBar setHidden:YES];
}

- (void)syncChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.noteArray = [[LocalDatabase sharedDatebase] getNoDeletedNote];
        [self refreshSearchArray];
        [self.noteTableView reloadData];
    });
}

- (void)goToNewTextVC {
    [_searchController.searchBar resignFirstResponder];
    TextViewController *textVC = [[TextViewController alloc] init];
    [textVC setHidesBottomBarWhenPushed:YES];
    [textVC setIsNewText:YES];
    [self.navigationController pushViewController:textVC animated:YES];
}

- (void)goToOldTextVCWithNote:(Note *)note {
    TextViewController *textVC = [[TextViewController alloc] init];
    [textVC setHidesBottomBarWhenPushed:YES];
    [textVC setIsNewText:NO];
    [textVC setNote:note];
    [self.navigationController pushViewController:textVC animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([_searchController.searchBar.text isEqualToString:@""]) {
        return _noteArray.count;
    }
    else {
        return _searchArray.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cell";
    NoteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell) {
        cell = [NoteTableViewCell xib];
    }
    Note *note;
    if([_searchController.searchBar.text isEqualToString:@""]) {
        note = [_noteArray objectAtIndex:indexPath.row];
    }
    else {
        note = [_searchArray objectAtIndex:indexPath.row];
    }
    cell.idNumber = note.idNumber;
    NSDate *time = note.time;
    cell.timeLabel.text = [_dateFormatter stringFromDate:time];
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *temp = [note.text stringByTrimmingCharactersInSet:set];
    if(temp.length > note.picNumber) {
        while([[temp substringToIndex:1] isEqualToString:@"\ufffc"]) {
            temp = [temp substringFromIndex:1];
            temp = [temp stringByTrimmingCharactersInSet:set];
        }
        cell.textLebel.text = temp;
    }
    else {
        cell.textLebel.text = @"（无文字内容）";
    }
    if(note.picNumber > 0) {
        [cell.picView setHidden:NO];
    }
    else {
        [cell.picView setHidden:YES];
    }
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"useTouchID"]) {
        [cell.lockView setHidden:!note.isLocked];
    }
    else {
        [cell.lockView setHidden:YES];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_searchController.searchBar resignFirstResponder];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NoteTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    Note *note = [[LocalDatabase sharedDatebase] getNoteWithId:cell.idNumber];
    
    LAContext *context = [[LAContext alloc] init];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"useTouchID"] && note.isLocked) {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:@"使用指纹或输入密码以查看此便签。" reply:^(BOOL success, NSError * _Nullable error) {
            if(success) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self goToOldTextVCWithNote:note];
                }];
            }
        }];
    }
    else {
        [self goToOldTextVCWithNote:note];
    }
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NoteTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    Note *note = [[LocalDatabase sharedDatebase] getNoteWithId:cell.idNumber];

    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        UIAlertController *deleteAlertController = [UIAlertController alertControllerWithTitle:nil message:@"此操作将不可恢复，你确定要删除吗？" preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            note.time = [NSDate date];
            [[LocalDatabase sharedDatebase] deleteNote:note];
            self.noteArray = [[LocalDatabase sharedDatebase] getNoDeletedNote];
            if(self.noteArray.count == 0) {
                [self.tineLabel setHidden:NO];
                [self.tineImageView setHidden:NO];
            }
            else {
                [self.tineLabel setHidden:YES];
                [self.tineImageView setHidden:YES];
            }

            [self refreshSearchArray];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        [deleteAlertController addAction:cancelAction];
        [deleteAlertController addAction:deleteAction];
        [self presentViewController:deleteAlertController animated:YES completion:nil];
    }];
    
    NSString *lockString;
    NSString *reasonString;
    if(note.isLocked) {
        lockString = @"取消加密";
        reasonString = @"请验证指纹或输入密码以取消加密。";
    }
    else {
        lockString = @"加密";
        reasonString = @"请验证指纹或输入密码以加密。";
    }
    UITableViewRowAction *lockAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:lockString handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        LAContext *context = [[LAContext alloc] init];
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:reasonString reply:^(BOOL success, NSError * _Nullable error) {
            if(success) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    note.isLocked = !note.isLocked;
                    [[LocalDatabase sharedDatebase] updateLockState:note.isLocked andLockChangeTime:[NSDate date] forId:note.idNumber];
                    self.noteArray = [[LocalDatabase sharedDatebase] getNoDeletedNote];
                    [self refreshSearchArray];
                    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }];
            }
        }];
    }];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"useTouchID"]) {
        return @[deleteAction, lockAction];
    }
    else {
        return @[deleteAction];
    }
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *inputString = searchController.searchBar.text;
    [_searchArray removeAllObjects];

    for(Note *note in _noteArray) {
        if([note.text.lowercaseString rangeOfString:inputString.lowercaseString].location != NSNotFound) {
            [_searchArray addObject:note];
        }
    }
    [_noteTableView reloadData];
}

- (void)refreshSearchArray {
    NSString *inputString = _searchController.searchBar.text;
    [_searchArray removeAllObjects];
    
    for(Note *note in _noteArray) {
        if([note.text.lowercaseString rangeOfString:inputString.lowercaseString].location != NSNotFound) {
            [_searchArray addObject:note];
        }
    }
}
@end
