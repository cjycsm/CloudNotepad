//
//  TextViewController.h
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/3/8.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Note;

@interface TextViewController : UIViewController

@property (nonatomic, assign) BOOL isNewText;

- (void)setNote:(Note *)note;

@end
