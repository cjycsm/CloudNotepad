//
//  NoteTableViewCell.h
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/4/23.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NoteTableViewCell : UITableViewCell

@property (assign, nonatomic) int idNumber;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *textLebel;
@property (weak, nonatomic) IBOutlet UIImageView *picView;
@property (weak, nonatomic) IBOutlet UIImageView *lockView;

+ (instancetype)xib;

@end
