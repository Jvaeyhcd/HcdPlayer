//
//  HcdFileManager.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FileType) {
    FileType_file_dir = 1,
    FileType_apk,
    FileType_html,
    FileType_img,
    FileType_ipa,
    FileType_music,
    FileType_pdf,
    FileType_ppt,
    FileType_torrent,
    FileType_txt,
    FileType_unkonwn,
    FileType_vcf,
    FileType_vedio,
    FileType_vsd,
    FileType_xls,
    FileType_zip,
    FileType_doc
};

@interface HcdFileManager : NSObject

+ (HcdFileManager *)defaultManager;

- (BOOL)createDir:(NSString *)dir inDir:(NSString *)inDir;

- (BOOL)createFile:(NSString *)name inDir:(NSString *)inDir;

- (NSDictionary *)fileAttriutes:(NSString *)path;

- (BOOL)deleteFileByPath:(NSString *)path;

- (BOOL)copyFile:(NSString *)path toPath:(NSString *)toPath;

- (BOOL)cutFile:(NSString *)path toPath:(NSString *)toPath;

- (NSMutableArray *)getAllFileByPath:(NSString *)path;

- (float)sizeOfPath:(NSString *)path;

- (BOOL)renameFileName:(NSString *)oldName newName:(NSString *)newName inPath:(NSString *)path;

- (FileType)getFileTypeByPath:(NSString *)path;

- (UIImage *)getFileTypeImageByPath:(NSString *)path;

- (NSString *)getFileSizeStrByPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
