//
//  HDownloadCell.m
//  HcdPlayer
//
//  Created by Salvador on 2020/1/13.
//  Copyright © 2020 Salvador. All rights reserved.
//

#import "HDownloadCell.h"
#import "HDownloadProgressView.h"
#import "HcdFileManager.h"

@interface HDownloadCell()

@property (nonatomic, strong) HDownloadProgressView *progressView;

@property (nonatomic, strong) UIImageView *fileTypeIV;

@property (nonatomic, strong) UILabel *fileNameLbl;

@property (nonatomic, strong) UILabel *statusLbl;

@property (nonatomic, strong) UILabel *sizeLbl;

@end

@implementation HDownloadCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.multipleSelectionBackgroundView = [UIView new];
        self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.frame];
        self.selectedBackgroundView.backgroundColor = kSelectedCellBgColor;
        
        [self.fileTypeIV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.mas_equalTo(kBasePadding);
            make.width.height.mas_equalTo(scaleFromiPhoneXDesign(50));
        }];
        
        [self.fileNameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.fileTypeIV.mas_top);
            make.left.equalTo(self.fileTypeIV.mas_right).offset(kBasePadding);
            make.height.mas_equalTo(20);
            make.right.mas_equalTo(-kBasePadding);
        }];
        
        [self.statusLbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.fileNameLbl.mas_left);
            make.height.mas_equalTo(20);
            make.bottom.equalTo(self.fileTypeIV.mas_bottom);
            make.width.mas_equalTo(100);
        }];
        
        [self.sizeLbl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.statusLbl.mas_right);
            make.top.equalTo(self.statusLbl.mas_top);
            make.right.equalTo(self.fileNameLbl.mas_right);
            make.height.mas_equalTo(20);
        }];
        
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.fileNameLbl.mas_left);
            make.right.equalTo(self.fileNameLbl.mas_right);
            make.height.mas_equalTo(2);
            make.centerY.equalTo(self.mas_centerY);
        }];
    }
    
    return self;
}

+ (CGFloat)cellHeight {
    return scaleFromiPhoneXDesign(50) + 2 * kBasePadding;
}

- (void)setModel:(HDownloadModel *)model {
    if (_model != model) {
        _model = model;
    }
    
    if (_model.filePath) {
        
        self.fileNameLbl.text = [_model.filePath lastPathComponent];
        
        NSString *suffix = [[_model.filePath pathExtension] lowercaseString];
        FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeBySuffix:suffix];
        
        self.fileTypeIV.image = [[HcdFileManager sharedHcdFileManager] getFileTypeImageByFileType:fileType];
    }
    
    if (_model.status == HCDDownloadStatusCompleted) {
        self.progressView.progress = 1.0;
    } else {
        self.progressView.progress = _model.progress;
    }
    self.statusLbl.text = [_model statusText];
    self.sizeLbl.text = [[HcdFileManager sharedHcdFileManager] formatSizeToStr:_model.size];
    
}

#pragma mark - lazy load

- (HDownloadProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[HDownloadProgressView alloc] init];
        [self.contentView addSubview:_progressView];
    }
    return _progressView;
}

- (UIImageView *)fileTypeIV {
    
    if (!_fileTypeIV) {
        _fileTypeIV = [[UIImageView alloc] init];
        _fileTypeIV.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_fileTypeIV];
    }
    return _fileTypeIV;
}

- (UILabel *)fileNameLbl {
    if (!_fileNameLbl) {
        _fileNameLbl = [[UILabel alloc] init];
        _fileNameLbl.font = kBoldFont(15);
        _fileNameLbl.textColor = [UIColor colorRGBHex:0x333333 darkColorRGBHex:0xffffff];
        _fileNameLbl.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_fileNameLbl];
    }
    return _fileNameLbl;
}

- (UILabel *)statusLbl {
    if (!_statusLbl) {
        _statusLbl = [[UILabel alloc] init];
        _statusLbl.font = [UIFont systemFontOfSize:12];
        _statusLbl.textColor = [UIColor color999];
        _statusLbl.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_statusLbl];
    }
    return _statusLbl;
}

- (UILabel *)sizeLbl {
    if (!_sizeLbl) {
        _sizeLbl = [[UILabel alloc] init];
        _sizeLbl.font = [UIFont systemFontOfSize:12];
        _sizeLbl.textColor = [UIColor color999];
        _sizeLbl.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_sizeLbl];
    }
    return _sizeLbl;
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
