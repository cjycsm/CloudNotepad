//
//  NoteTableViewCell.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/4/23.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "NoteTableViewCell.h"

@implementation NoteTableViewCell

+ (instancetype)xib {
    return [[[NSBundle mainBundle] loadNibNamed:@"NoteTableViewCell" owner:nil options:nil] firstObject];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
