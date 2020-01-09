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
    FileType_video,
    FileType_vsd,
    FileType_xls,
    FileType_zip,
    FileType_doc
};

@interface HcdFileManager : NSObject

SingletonH(HcdFileManager)

- (BOOL)createDir:(NSString *)dir inDir:(NSString *)inDir;

- (BOOL)createFile:(NSString *)name inDir:(NSString *)inDir;

- (NSDictionary *)fileAttriutes:(NSString *)path;

- (BOOL)deleteFileByPath:(NSString *)path;

- (BOOL)copyFile:(NSString *)path toPath:(NSString *)toPath;

- (BOOL)cutFile:(NSString *)path toPath:(NSString *)toPath;

/// 获取该路径下的所有文件
/// @param path 路径
- (NSMutableArray *)getAllFileByPath:(NSString *)path;

/// 获取指定文件夹下的所有文件夹
/// @param path 指定文件夹路径
- (NSMutableArray *)getAllFolderByPath:(NSString *)path;

/// 获取指定文件夹下的所有图片
/// @param path 指定文件夹路径
- (NSMutableArray *)getAllImagesByPath:(NSString *)path;

- (NSMutableArray *)getAllImagesInPathArray:(NSMutableArray *)array withPath:(NSString *)path;

/// 获取指定路路径的文件或者文件夹的大小
/// @param path 路径
- (float)sizeOfPath:(NSString *)path;

/// 重命名文件或文件夹
/// @param oldName 旧名称
/// @param newName 新名称
/// @param path 文件所在文件夹的路径
- (BOOL)renameFileName:(NSString *)oldName newName:(NSString *)newName inPath:(NSString *)path;

/// 获取文件的类型
/// @param path 文件类型
- (FileType)getFileTypeByPath:(NSString *)path;

/// 根据文件的扩展名获得文章类型
/// @param suffix 扩展名
- (FileType)getFileTypeBySuffix:(NSString *)suffix;

- (UIImage *)getFileTypeImageByPath:(NSString *)path;

- (UIImage *)getFileTypeImageByFileType:(FileType)type;

- (NSString *)getFileSizeStrByPath:(NSString *)path;

- (NSString *)formatSizeToStr:(double)size;

- (NSDictionary *)getFileInfoByPath:(NSString *)path;

- (BOOL)fileExists:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
