//
//  Note.h
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/4/23.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Note : NSObject

@property (nonatomic, assign) int idNumber;
@property (nonatomic, strong) NSDate *time;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSData *pic;
@property (nonatomic, assign) NSUInteger picNumber;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, strong) NSDate *lockChangeTime;
@property (nonatomic, strong) NSData *authors;
@property (nonatomic, assign) BOOL isDeleted;

@end
