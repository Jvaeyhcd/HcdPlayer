//
//  FilesListTableViewCell.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "FilesListTableViewCell.h"
#import "HcdFileManager.h"
//#import "HcdMovieDecoder.h"

@interface FilesListTableViewCell() {
    UIImageView                 *_fileTypeImageView;
    UILabel                     *_titleLbl;
    UILabel                     *_descLbl;
}

@end

@implementation FilesListTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    
//    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.multipleSelectionBackgroundView = [UIView new];
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
    self.selectedBackgroundView.backgroundColor = kSelectedCellBgColor;
    
    if (!_fileTypeImageView) {
        _fileTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kBasePadding, kBasePadding, scaleFromiPhoneXDesign(50), scaleFromiPhoneXDesign(50))];
        _fileTypeImageView.backgroundColor = [UIColor colorWithRGBHex:0xFFFFFF];
        _fileTypeImageView.contentMode = UIViewContentModeScaleAspectFit;
        _fileTypeImageView.clipsToBounds = YES;
        [self.contentView addSubview:_fileTypeImageView];
    }
    
    if (!_titleLbl) {
        _titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(_fileTypeImageView.frame.origin.x + _fileTypeImageView.frame.size.width + kBasePadding, _fileTypeImageView.frame.origin.y, kScreenWidth - (_fileTypeImageView.frame.origin.x + _fileTypeImageView.frame.size.width + 3 * kBasePadding), scaleFromiPhoneXDesign(30))];
        _titleLbl.font = kBoldFont(15);
        _titleLbl.textAlignment = NSTextAlignmentLeft;
        _titleLbl.textColor = [UIColor color333];
        _titleLbl.text = HcdLocalized(@"local", nil);
        _titleLbl.numberOfLines = 1;
        [self.contentView addSubview:_titleLbl];
    }
    
    
    if (!_descLbl) {
        _descLbl = [[UILabel alloc] init];
        _descLbl.frame = CGRectMake(_fileTypeImageView.frame.origin.x + _fileTypeImageView.frame.size.width + kBasePadding, _titleLbl.frame.origin.y + _titleLbl.frame.size.height, kScreenWidth - (_fileTypeImageView.frame.origin.x + _fileTypeImageView.frame.size.width + 3 * kBasePadding), scaleFromiPhoneXDesign(20));
        _descLbl.font = kFont(12);
        _descLbl.textAlignment = NSTextAlignmentLeft;
        _descLbl.textColor = [UIColor color666];
        _descLbl.text = HcdLocalized(@"local", nil);
        _descLbl.numberOfLines = 1;
        [self.contentView addSubview:_descLbl];
    }
}

- (void)setFilePath:(NSString *)path {
    NSString *fileName = [[path stringByDeletingPathExtension] lastPathComponent];
    NSString *suffix = [path pathExtension];
    
    NSMutableArray *descArr = [[NSMutableArray alloc] init];
    
    NSDictionary *fileInfo = [[HcdFileManager defaultManager] getFileInfoByPath:path];
    NSDate *date = [fileInfo fileCreationDate];
    if (date) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];
        [descArr addObject:[formatter stringFromDate:date]];
    }
    
    FileType fileType = [[HcdFileManager defaultManager] getFileTypeByPath:path];
    if (fileType != FileType_unkonwn && fileType != FileType_file_dir) {
        [descArr addObject:suffix];
    }
    // 如果是视频文件，获取视频文件的时长
    if (fileType == FileType_video) {
//        HcdMovieInfo *info = [HcdMovieDecoder videoInfoWithContentPath:path];
//        [descArr addObject:info.durationStr];
    }
    NSString *size = [[HcdFileManager defaultManager] getFileSizeStrByPath:path];
    if (size) {
        [descArr addObject:size];
    }
    if (fileType == FileType_img) {
        _fileTypeImageView.image = [UIImage imageWithContentsOfFile:path];
    } else {
        _fileTypeImageView.image = [[HcdFileManager defaultManager] getFileTypeImageByPath:path];
    }
    _titleLbl.text = fileName;
    _descLbl.text = [descArr componentsJoinedByString:@" | "];
    self.accessoryType = fileType == FileType_file_dir ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
}

- (void)setFaterFolder:(NSString *)path {
    NSString *name = [[path stringByDeletingLastPathComponent] lastPathComponent];
    _fileTypeImageView.image = [UIImage imageNamed:@"hcdplayer.bundle/barcode_result_page_type_file_dir_icon.png"];
    _titleLbl.text = @"..";
    if (name) {
        _descLbl.text = name;
    }
}

- (void)setNetworkService:(NetworkService *)service {
    
    if (!service) {
        return;
    }
    
    if (service.type == NetworkServiceTypeSMB) {
        _fileTypeImageView.image = [UIImage imageNamed:@"hcdplayer.bundle/icon_server_smb"];
    }
    _titleLbl.text = service.title;
    _descLbl.text = service.host;
    
}

- (void)setTOSMBSessionFile:(TOSMBSessionFile *)file {
    _titleLbl.text = file.name;
    if (file.directory) {
        _descLbl.text = @"Directory";
        _fileTypeImageView.image = [UIImage imageNamed:@"hcdplayer.bundle/barcode_result_page_type_file_dir_icon.png"];
    } else {
        NSString *size = [[HcdFileManager defaultManager] formatSizeToStr:file.fileSize];
        _descLbl.text = [NSString stringWithFormat:@"File | Size: %@", size];

        NSString *suffix = [[file.filePath pathExtension] lowercaseString];
        FileType fileType = [[HcdFileManager defaultManager] getFileTypeBySuffix:suffix];
        
        _fileTypeImageView.image = [[HcdFileManager defaultManager] getFileTypeImageByFileType:fileType];
    }
    self.accessoryType = file.directory ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
}

+ (CGFloat)cellHeight {
    return scaleFromiPhoneXDesign(50) + kBasePadding * 2;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    for (UIControl *control in self.subviews) {
        if ([control isKindOfClass:NSClassFromString(@"UITableViewCellEditControl")]) {
            for (UIView *v in control.subviews) {
                if ([v isKindOfClass:[UIImageView class]]) {
                    UIImageView *img = (UIImageView *)v;
                    if (!self.isSelected) {
                        img.image = [UIImage imageNamed:@"hcdplayer.bundle/checkbox_circle"];
                    }
                }
            }
        }
    }
}

- (void)layoutSubviews {
    for (UIControl *control in self.subviews) {
        if ([control isKindOfClass:NSClassFromString(@"UITableViewCellEditControl")]) {
            for (UIView *v in control.subviews) {
                if ([v isKindOfClass:[UIImageView class]]) {
                    UIImageView *img = (UIImageView *)v;
                    if (self.isSelected) {
                        img.image = [UIImage imageNamed:@"hcdplayer.bundle/checkbox_circle_selected"];
                    } else {
                        img.image = [UIImage imageNamed:@"hcdplayer.bundle/checkbox_circle"];
                    }
                }
            }
        }
    }
    [super layoutSubviews];
}

@end
