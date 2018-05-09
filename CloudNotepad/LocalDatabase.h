//
//  LocalDatabase.h
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/4/2.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Note;

@interface LocalDatabase : NSObject

@property (nonatomic, strong)Note *note;

+ (instancetype)sharedDatebase;

- (void)addNote:(Note *)note;
- (void)deleteNote:(Note *)note;
- (void)updateNote:(Note *)note;
- (void)updateLockState:(BOOL)lockState andLockChangeTime:(NSDate *)time forId:(int)idNumber;
- (void)updateAuthor:(NSData *)author forId:(int)idNumber;
- (Note *)getNoteWithId:(int)idNumber;
- (NSMutableArray *)getAllNote;
- (NSMutableArray *)getNoDeletedNote;
- (int)getLastId;

@end
