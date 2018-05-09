//
//  LocalDatabase.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/4/2.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "LocalDatabase.h"
#import "FMDB.h"
#import "Note.h"

#define dataBasePath [[(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)) lastObject]stringByAppendingPathComponent:dataBaseName]
#define dataBaseName @"local.sqlite"
static LocalDatabase *_DBCtl = nil;

@interface LocalDatabase()<NSCopying, NSMutableCopying>

@property (nonatomic, strong) FMDatabase *db;

@end

@implementation LocalDatabase

+ (instancetype)sharedDatebase {
    @synchronized(self) {
        if(_DBCtl == nil) {
            _DBCtl = [[LocalDatabase alloc] init];
            [_DBCtl initWithDatabase];
        }
    }
    return _DBCtl;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    @synchronized(self) {
        if(_DBCtl == nil) {
            _DBCtl = [super allocWithZone:zone];
        }
    }
    return _DBCtl;
}

- (id)copy {
    return self;
}

- (id)mutableCopy {
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return self;
}

- (void)initWithDatabase {
    _db = [FMDatabase databaseWithPath:dataBasePath];
    [_db open];
    NSString *noteSql = @"CREATE TABLE IF NOT EXISTS note('id' INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 'pic' BLOB, 'text' TEXT, 'time' TEXT NOT NULL, 'picNumber' UNSIGNED BIG INT, 'lockState' BOOLEAN DEFAULT 0, 'authors' BLOB, 'deleted' BOOLEAN DEFAULT 0, 'lockChangeTime' TEXT)";
    [_db executeUpdate:noteSql];
    [_db close];
}

- (void)addNote:(Note *)note {
    [_db open];
    [_db executeUpdate:@"INSERT INTO note (pic, text, time, picNumber, lockstate) VALUES (?, ?, ?, ?, ?)", note.pic, note.text, note.time, @(note.picNumber), @(note.isLocked)];
    [_db close];
}

- (void)updateNote:(Note *)note {
    [_db open];
    [_db executeUpdate:@"UPDATE note SET pic = ?, text = ?, time = ?, picNumber = ?, lockstate = ? WHERE id = ?", note.pic, note.text, note.time, @(note.picNumber), @(note.isLocked), @(note.idNumber)];
    [_db close];
}

- (void)updateLockState:(BOOL)lockState andLockChangeTime:(NSDate *)time forId:(int)idNumber {
    [_db open];
    [_db executeUpdate:@"UPDATE note SET lockChangeTime = ?, lockState = ? WHERE id = ?", time, @(lockState), @(idNumber)];
    [_db close];
}

- (void)updateAuthor:(NSData *)author forId:(int)idNumber {
    [_db open];
    [_db executeUpdate:@"UPDATE note SET authors = ? WHERE id = ?", author, @(idNumber)];
    [_db close];

}

- (void)deleteNote:(Note *)note {
    [_db open];
    [_db executeUpdate:@"UPDATE note SET time = ?, deleted = 1 WHERE id = ?", note.time, @(note.idNumber)];
    [_db close];
}

- (Note *)getNoteWithId:(int)idNumber {
    Note *note = [[Note alloc] init];
    if([_db open]) {
        FMResultSet *res = [_db executeQuery:@"SELECT * FROM note WHERE id = ?", @(idNumber)];
        [res next];
        note.idNumber = [res intForColumn:@"id"];
        note.pic = [res dataForColumn:@"pic"];
        note.text = [res stringForColumn:@"text"];
        note.time = [res dateForColumn:@"time"];
        note.picNumber = [res unsignedLongLongIntForColumn:@"picNumber"];
        note.isLocked = [res boolForColumn:@"lockState"];
        note.lockChangeTime = [res dateForColumn:@"lockChangeTime"];
        note.authors = [res dataForColumn:@"authors"];
        note.isDeleted = [res boolForColumn:@"deleted"];
    }
    [_db close];
    return note;
}

- (NSMutableArray *)getAllNote {
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    if([_db open]) {
        FMResultSet *res = [_db executeQuery:@"SELECT * FROM note ORDER BY time DESC"];
        while ([res next]) {
            Note *note = [[Note alloc] init];
            note.idNumber = [res intForColumn:@"id"];
            note.pic = [res dataForColumn:@"pic"];
            note.text = [res stringForColumn:@"text"];
            note.time = [res dateForColumn:@"time"];
            note.picNumber = [res unsignedLongLongIntForColumn:@"picNumber"];
            note.isLocked = [res boolForColumn:@"lockState"];
            note.lockChangeTime = [res dateForColumn:@"lockChangeTime"];
            note.authors = [res dataForColumn:@"authors"];
            note.isDeleted = [res boolForColumn:@"deleted"];
            [dataArray addObject:note];
        }
    }
    [_db close];
    return dataArray;
}

- (NSMutableArray *)getNoDeletedNote {
    NSMutableArray *dataArray = [[NSMutableArray alloc] init];
    if([_db open]) {
        FMResultSet *res = [_db executeQuery:@"SELECT * FROM note WHERE deleted = 0 ORDER BY time DESC"];
        while ([res next]) {
            Note *note = [[Note alloc] init];
            note.idNumber = [res intForColumn:@"id"];
            note.pic = [res dataForColumn:@"pic"];
            note.text = [res stringForColumn:@"text"];
            note.time = [res dateForColumn:@"time"];
            note.picNumber = [res unsignedLongLongIntForColumn:@"picNumber"];
            note.isLocked = [res boolForColumn:@"lockState"];
            note.lockChangeTime = [res dateForColumn:@"lockChangeTime"];
            note.authors = [res dataForColumn:@"authors"];
            note.isDeleted = [res boolForColumn:@"deleted"];
            [dataArray addObject:note];
        }
    }
    [_db close];
    return dataArray;
}

- (int)getLastId {
    int idNumber = 0;
    if([_db open]) {
        FMResultSet *res = [_db executeQuery:@"SELECT * FROM note ORDER BY id DESC LIMIT 1"];
        [res next];
        idNumber = [res intForColumn:@"id"];
    }
    [_db close];
    return idNumber;
}

@end
