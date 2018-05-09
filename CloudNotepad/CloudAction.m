//
//  CloudAction.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/5/2.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "CloudAction.h"
#import "Note.h"
#import "LocalDatabase.h"
#import <SDWebImageManager.h>
#import <BmobSDK/Bmob.h>

@implementation CloudAction

+ (void)upload {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isSync"];
    NSNotification *noti = [NSNotification notificationWithName:@"startSync" object:nil];
    [[NSNotificationCenter defaultCenter] postNotification:noti];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_async(queue, ^{
        NSString *idvf = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSDate *lastUpdateTime = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"lastUpdateTimeFor%@", [BmobUser currentUser].username]];
        BmobObjectsBatch *batch = [[BmobObjectsBatch alloc] init];
        NSArray *noteArray = [[LocalDatabase sharedDatebase] getAllNote];
        NSMutableArray *addArray = [[NSMutableArray alloc] init];
        NSMutableArray *indexArray = [[NSMutableArray alloc] init];
        NSMutableArray *uploadArray = [[NSMutableArray alloc] init];
        int i = 0;
        for(Note *note in noteArray) {
            if(lastUpdateTime && [note.time compare:lastUpdateTime] == NSOrderedAscending) {
                if(!note.lockChangeTime || [note.lockChangeTime compare:lastUpdateTime] == NSOrderedAscending)
                continue;
            }
            NSMutableDictionary *authorDic = [NSKeyedUnarchiver unarchiveObjectWithData:note.authors];
            BOOL isExisted = NO;
            for(NSString *author in [authorDic keyEnumerator]) {
                if([author isEqualToString:[BmobUser currentUser].username]) {
                    isExisted = YES;
                    break;
                }
            }
            if(isExisted) {
                NSString *cloudId = [authorDic objectForKey:[BmobUser currentUser].username];
                [uploadArray addObject:cloudId];
                if(note.isDeleted) {
                    [batch deleteBmobObjectWithClassName:@"note" objectId:cloudId];
                }
                else {
                    __block NSMutableDictionary *deviceDic;
                    BmobQuery *bquery = [BmobQuery queryWithClassName:@"note"];
                    [bquery getObjectInBackgroundWithId:cloudId block:^(BmobObject *object, NSError *error) {
                        deviceDic = [object objectForKey:@"device"];
                        dispatch_semaphore_signal(semaphore);
                    }];
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                    [deviceDic setObject:@(note.idNumber) forKey:idvf];
                    if(lastUpdateTime && [note.time compare:lastUpdateTime] == NSOrderedDescending && note.lockChangeTime && [note.lockChangeTime compare:lastUpdateTime] == NSOrderedAscending) {
                        [batch updateBmobObjectWithClassName:@"note" objectId:cloudId parameters:@{@"isLocked":@(note.isLocked)}];
                        continue;
                    }
                    NSArray *picArray = [NSKeyedUnarchiver unarchiveObjectWithData:note.pic];
                    if(picArray.count > 0) {
                        NSMutableArray *picUrlArray = [[NSMutableArray alloc] init];
                        NSMutableArray *picDataArray = [[NSMutableArray alloc] init];
                        for(UIImage *pic in picArray) {
                            NSData *picData = UIImagePNGRepresentation(pic);
                            NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
                            NSString *picName = [NSString stringWithFormat:@"%.0f.png", time * 1000];
                            [picDataArray addObject:@{@"filename":picName, @"data":picData}];
                        }
                        [BmobFile filesUploadBatchWithDataArray:picDataArray progressBlock:nil resultBlock:^(NSArray *array, BOOL isSuccessful, NSError *error) {
                            for(BmobFile *picFile in array) {
                                [picUrlArray addObject:picFile.url];
                            }
                            dispatch_semaphore_signal(semaphore);
                        }];
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        [batch updateBmobObjectWithClassName:@"note" objectId:cloudId parameters:@{@"text":note.text, @"pic":picUrlArray, @"picNumber": @(note.picNumber), @"device":deviceDic, @"isLocked":@(note.isLocked)}];

                    }
                    else {
                    [batch updateBmobObjectWithClassName:@"note" objectId:cloudId parameters:@{@"text":note.text, @"pic":@[], @"picNumber": @0, @"device":deviceDic, @"isLocked":@(note.isLocked)}];
                    }
                }
            }
            else {
                if(note.isDeleted) {
                    continue;
                }
                NSArray *picArray = [NSKeyedUnarchiver unarchiveObjectWithData:note.pic];
                if(picArray.count > 0) {
                    NSMutableArray *picUrlArray = [[NSMutableArray alloc] init];
                    NSMutableArray *picDataArray = [[NSMutableArray alloc] init];
                    for(UIImage *pic in picArray) {
                        NSData *picData = UIImagePNGRepresentation(pic);
                        NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
                        NSString *picName = [NSString stringWithFormat:@"%.0f.png", time * 1000];
                        [picDataArray addObject:@{@"filename":picName, @"data":picData}];
                    }
                    [BmobFile filesUploadBatchWithDataArray:picDataArray progressBlock:nil resultBlock:^(NSArray *array, BOOL isSuccessful, NSError *error) {
                        for(BmobFile *picFile in array) {
                            [picUrlArray addObject:picFile.url];
                        }
                        dispatch_semaphore_signal(semaphore);
                    }];
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                    [batch saveBmobObjectWithClassName:@"note" parameters:@{@"text":note.text, @"pic":picUrlArray, @"picNumber": @(note.picNumber), @"device":@{idvf:@(note.idNumber)}, @"isLocked":@(note.isLocked), @"author":[BmobUser currentUser].username}];
                    
                }
                else {
                    [batch saveBmobObjectWithClassName:@"note" parameters:@{@"text":note.text,  @"picNumber": @0, @"device":@{idvf:@(note.idNumber)}, @"isLocked":@(note.isLocked), @"author":[BmobUser currentUser].username}];
                }
                [addArray addObject:note];
                [indexArray addObject:@(i++)];
            }
        }
        [batch batchObjectsInBackground:^(NSArray *results, NSError *error) {
            NSLog(@"%@", results);
            for(int i = 0; i < addArray.count; i++) {
                NSDictionary *successDic = [((NSDictionary *)results[i]) objectForKey:@"success"];
                if(successDic) {
                    NSString *cloudId = [successDic objectForKey:@"objectId"];
                    NSMutableDictionary *authorDic = [NSKeyedUnarchiver unarchiveObjectWithData:((Note *)addArray[i]).authors];
                    if(!authorDic) {
                        authorDic = [[NSMutableDictionary alloc] init];
                    }
                    [authorDic setValue:cloudId forKey:[BmobUser currentUser].username];
                    [[LocalDatabase sharedDatebase] updateAuthor:[NSKeyedArchiver archivedDataWithRootObject:authorDic] forId:((Note *)addArray[i]).idNumber];
                }
            }
            for(NSDictionary *dic in results) {
                NSDictionary *successDic = [dic objectForKey:@"success"];
                if(successDic) {
                    NSString *cloudId = [successDic objectForKey:@"objectId"];
                    if(cloudId) {
                        [uploadArray addObject:cloudId];
                    }
                }
            }
            [CloudAction downloadExpectUploadArray:uploadArray];
        }];
    });
}

+ (void)downloadExpectUploadArray:(NSArray *)uploadArray {
    BmobQuery *bquery = [BmobQuery queryWithClassName:@"note"];
    [bquery whereKey:@"author" equalTo:[BmobUser currentUser].username];
    [bquery findObjectsInBackgroundWithBlock:^(NSArray *array, NSError *error) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
        dispatch_async(queue, ^{
            NSString *idvf = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            NSDate *lastUpdateTime = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"lastUpdateTimeFor%@", [BmobUser currentUser].username]];
            for (BmobObject *obj in array) {
                BOOL isUploaded = NO;
                for(NSString *cloudId in uploadArray) {
                    if([cloudId isEqualToString:[obj objectId]]) {
                        isUploaded = YES;
                        break;
                    }
                }
                if(isUploaded) {
                    continue;
                }
                
                if([[obj updatedAt] compare:lastUpdateTime] == NSOrderedAscending) {
                    continue;
                }
                else {
                    NSArray *picUrlArray = [obj objectForKey:@"pic"];
                    NSMutableArray *picArray = [[NSMutableArray alloc] init];
                    SDWebImageManager *webImageManager = [SDWebImageManager sharedManager];
                    for(NSString *picUrlString in picUrlArray) {
                        NSURL *picUrl = [NSURL URLWithString:picUrlString];
                        [webImageManager loadImageWithURL:picUrl options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                            CGSize size = CGSizeMake(image.size.width / 2, image.size.height / 2);
                            UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
                            [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
                            UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                            [picArray addObject:resultImage];
                            dispatch_semaphore_signal(semaphore);
                        }];
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                    }
                    Note *note;
                    if([[obj createdAt] compare:lastUpdateTime] == NSOrderedAscending) {
                        NSDictionary *deviceDic = [obj objectForKey:@"device"];
                        int localId = [[deviceDic objectForKey:idvf] intValue];
                        note = [[LocalDatabase sharedDatebase] getNoteWithId:localId];
                        note.text = [obj objectForKey:@"text"];
                        note.picNumber = [[obj objectForKey:@"picNumber"] unsignedIntegerValue];
                        note.pic = [NSKeyedArchiver archivedDataWithRootObject:picArray];
                        note.time = [NSDate date];
                        [[LocalDatabase sharedDatebase] updateNote:note];
                    }
                    else {
                        note = [[Note alloc] init];
                        note.text = [obj objectForKey:@"text"];
                        note.picNumber = [[obj objectForKey:@"picNumber"] unsignedIntegerValue];
                        note.pic = [NSKeyedArchiver archivedDataWithRootObject:picArray];
                        note.time = [NSDate date];
                        int idNumber = [[LocalDatabase sharedDatebase] getLastId] + 1;
                        [[LocalDatabase sharedDatebase] addNote:note];
                        NSDictionary *authorDic = @{[BmobUser currentUser].username:[obj objectId]};
                        NSData *author = [NSKeyedArchiver archivedDataWithRootObject:authorDic];
                        [[LocalDatabase sharedDatebase] updateAuthor:author forId:idNumber];
                    }
                }
            }
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:[NSString stringWithFormat:@"lastUpdateTimeFor%@", [BmobUser currentUser].username]];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isSync"];
            NSNotification *noti = [NSNotification notificationWithName:@"finishSync" object:nil];
            [[NSNotificationCenter defaultCenter] postNotification:noti];
        });
    }];
}

@end
