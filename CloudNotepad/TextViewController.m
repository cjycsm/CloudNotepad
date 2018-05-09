//
//  TextViewController.m
//  CloudNotepad
//
//  Created by 陈嘉谊 on 2018/3/8.
//  Copyright © 2018年 陈嘉谊. All rights reserved.
//

#import "TextViewController.h"
#import "ShareViewController.h"
#import "YYText.h"
#import "Masonry.h"
#import "LocalDatabase.h"
#import "Note.h"

@interface TextViewController ()<UIScrollViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) YYTextView *textView;
@property (strong, nonatomic) UIImagePickerController *imagePickerController;
@property (assign, nonatomic) BOOL isInsertingPic;
@property (strong, nonatomic) Note *note;

@end

@implementation TextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepare];
    [self configUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    if([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *temp = [_textView.text stringByTrimmingCharactersInSet:set];
        if(temp.length != 0) {
            [self saveData];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepare {
    _textView = [[YYTextView alloc] init];
    if(_isNewText) {
        _note = [[Note alloc] init];
    }
    
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.delegate = self;
}

- (void)configUI {
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIBarButtonItem *deleteButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteNote)];
    UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"] style:UIBarButtonItemStylePlain target:self action:@selector(showShare)];
    [self.navigationItem setRightBarButtonItems:@[shareButtonItem, deleteButtonItem]];

    [_textView setBackgroundColor:[UIColor clearColor]];
    [_textView setFont:[UIFont systemFontOfSize:16]];
    [_textView setAllowsPasteImage:YES];
    [_textView setDataDetectorTypes:UIDataDetectorTypeAll];
    [_textView setAllowsPasteAttributedString:NO];
    
    [self.view addSubview:_textView];
    [_textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view).with.insets(UIEdgeInsetsMake(0, 10, 0, 10));
    }];
    [_textView setContentInset:UIEdgeInsetsMake(8, 0, 8, 0)];
    [_textView setShowsVerticalScrollIndicator:NO];
    [_textView setShowsHorizontalScrollIndicator:NO];
    [_textView setTextColor:[UIColor colorWithRed:50.0 / 255 green:50.0 / 255 blue:50.0 / 255 alpha:1]];
    if(_isNewText) {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 6;// 字体的行间距
        paragraphStyle.paragraphSpacing = 6;
        NSDictionary *attributes = @{
                                     NSFontAttributeName:[UIFont systemFontOfSize:16],
                                     NSParagraphStyleAttributeName:paragraphStyle
                                     };
        _textView.typingAttributes = attributes;

        [_textView setText:nil];
        [_textView becomeFirstResponder];
    }
    else {
        [_textView setText:_note.text];
        NSData *picData = _note.pic;
        NSArray *picArray = [NSKeyedUnarchiver unarchiveObjectWithData:picData];
        NSMutableArray *locationArray = [[NSMutableArray alloc] init];
        while([_textView.text rangeOfString:@"\ufffc"].length != 0) {
            NSRange range = [_textView.text rangeOfString:@"\ufffc"];
            _textView.text = [_textView.text stringByReplacingCharactersInRange:range withString:@""];
            [locationArray addObject:@(range.location)];
        }
        for(int i = (int)locationArray.count - 1; i >= 0; i--) {
            UIImage *pic = picArray[i];

            NSMutableAttributedString *context = [[NSMutableAttributedString alloc] initWithAttributedString:_textView.attributedText];
            UIFont *font = [UIFont systemFontOfSize:16];
            
            NSMutableAttributedString *attachment = [NSMutableAttributedString yy_attachmentStringWithContent:pic contentMode:UIViewContentModeCenter attachmentSize:pic.size alignToFont:font alignment:YYTextVerticalAlignmentCenter];
            [context insertAttributedString:attachment atIndex:[locationArray[i] integerValue]];
            _textView.attributedText = context;
        }
        NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString:_textView.attributedText];
        [_textView setFont:[UIFont systemFontOfSize:16]];
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineSpacing = 6;// 字体的行间距
        paragraphStyle.paragraphSpacing = 6;
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:16], NSParagraphStyleAttributeName:paragraphStyle};
        [text addAttributes:attributes range:NSMakeRange(0, text.length)];
        _textView.attributedText = text;
        _textView.typingAttributes = attributes;
    }
}

- (void)setNote:(Note *)note {
    _note = note;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    UIBarButtonItem *finishButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"finish"] style:UIBarButtonItemStylePlain target:self action:@selector(finishEditing)];
    UIBarButtonItem *pictureButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"picture"] style:UIBarButtonItemStylePlain target:self action:@selector(insertPic)];
    [self.navigationItem setRightBarButtonItems:@[finishButtonItem, pictureButtonItem]];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    UIBarButtonItem *deleteButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteNote)];
    UIBarButtonItem *shareButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"] style:UIBarButtonItemStylePlain target:self action:@selector(showShare)];
    [self.navigationItem setRightBarButtonItems:@[shareButtonItem, deleteButtonItem]];
}

- (void)deleteNote {
    UIAlertController *deleteAlertController = [UIAlertController alertControllerWithTitle:nil message:@"此操作将不可恢复，你确定要删除吗？" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        self.note.time = [NSDate date];
        [[LocalDatabase sharedDatebase] deleteNote:self.note];
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [deleteAlertController addAction:cancelAction];
    [deleteAlertController addAction:deleteAction];
    [self presentViewController:deleteAlertController animated:YES completion:nil];
}

- (void)saveData {
    if([_note.text isEqualToString:_textView.text]) {
        return;
    }
    _note.time =[NSDate date];
    _note.text = _textView.text;
    _note.picNumber = _textView.textLayout.attachments.count;
    NSMutableArray *picArray = [[NSMutableArray alloc] init];
    for(YYTextAttachment *att in _textView.textLayout.attachments) {
        UIImage *pic = att.content;
        [picArray addObject:pic];
    }
    NSData *picData = [NSKeyedArchiver archivedDataWithRootObject:picArray];
    _note.pic = picData;

    if(_isNewText) {
        [[LocalDatabase sharedDatebase] addNote:_note];
        _isNewText = NO;
        _note.idNumber = [[LocalDatabase sharedDatebase] getLastId];
    }
    else {
        [[LocalDatabase sharedDatebase] updateNote:_note];
    }
}

- (void)finishEditing {
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *temp = [_textView.text stringByTrimmingCharactersInSet:set];
    if(temp.length == 0) {
        if(_isNewText) {
            [self.navigationController popViewControllerAnimated:YES];
            return;
        }
    }
    [_textView resignFirstResponder];
    [self saveData];
}

- (void)insertPic {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }];
    UIAlertAction *photoLibraryAction = [UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cameraAction];
    [alertController addAction:photoLibraryAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showShare {
    CGSize s = _textView.contentSize;
    // 下面方法，第一个参数表示区域大小。第二个参数表示是否是非透明的。如果需要显示半透明效果，需要传NO，否则传YES。第三个参数就是屏幕密度了
    UIGraphicsBeginImageContextWithOptions(s, NO, [UIScreen mainScreen].scale);
    
    CGPoint savedContentOffset = _textView.contentOffset;
    CGRect savedFrame = _textView.frame;
    _textView.contentOffset = CGPointZero;
    _textView.frame = CGRectMake(0, 0, _textView.contentSize.width, _textView.contentSize.height);
    
    [_textView.layer renderInContext: UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    _textView.contentOffset = savedContentOffset;
    _textView.frame = savedFrame;
    
    UIGraphicsEndImageContext();

    ShareViewController *shareVc = [[ShareViewController alloc] init];
    [shareVc setShareImage:image];
    [shareVc setTime:_note.time];
    [self.navigationController pushViewController:shareVc animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        self.isInsertingPic = NO;
    }];
    
    NSMutableAttributedString *context = [[NSMutableAttributedString alloc] initWithAttributedString:_textView.attributedText];
    UIFont *font = [UIFont systemFontOfSize:16];
    NSMutableAttributedString *attachment = nil;
    
    CGFloat width = (_textView.frame.size.width - 9);
    CGFloat height = image.size.height / image.size.width * width;
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    attachment = [NSMutableAttributedString yy_attachmentStringWithContent:resultImage contentMode:UIViewContentModeCenter attachmentSize:size alignToFont:font alignment:YYTextVerticalAlignmentCenter];

    NSRange range = _textView.selectedRange;
    if(![[_textView.text substringWithRange:NSMakeRange(range.location - 1, 1)] isEqualToString:@"\n"]) {
        [_textView insertText: @"\n"];
    }
   [context insertAttributedString:attachment atIndex:range.location];
    _textView.attributedText = context;
    _textView.selectedRange = NSMakeRange(0, 0);
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString:_textView.attributedText];
    [_textView setFont:[UIFont systemFontOfSize:16]];
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.lineSpacing = 6;// 字体的行间距
    paragraphStyle.paragraphSpacing = 6;
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:16], NSParagraphStyleAttributeName:paragraphStyle};
    [text addAttributes:attributes range:NSMakeRange(0, text.length)];
    _textView.attributedText = text;
    _textView.typingAttributes = attributes;
    
    [_textView becomeFirstResponder];
    _textView.selectedRange = NSMakeRange(range.location, 0);
    if(![[_textView.text substringWithRange:NSMakeRange(range.location - 1, 1)] isEqualToString:@"\n"] && range.location != 0) {
        [_textView insertText:@"\n"];
        range = NSMakeRange(range.location + 1, 0);
    }
    _textView.selectedRange = NSMakeRange(range.location + 1, 0);
    if(_textView.attributedText.length < range.location + 2 || ![[_textView.text substringWithRange:NSMakeRange(range.location + 1, 1)] isEqualToString:@"\n"]) {
        [_textView insertText:@"\n"];
    }
    _textView.selectedRange = NSMakeRange(range.location + 2, 0);
    
    [_textView setTextColor:[UIColor colorWithRed:50.0 / 255 green:50.0 / 255 blue:50.0 / 255 alpha:1]];
}

@end
