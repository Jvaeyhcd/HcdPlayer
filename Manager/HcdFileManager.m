//
//  HcdFileManager.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/21.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdFileManager.h"

@interface HcdFileManager()

@property (nonatomic, retain) NSFileManager *fileManager;

@end

@implementation HcdFileManager

SingletonM(HcdFileManager)

- (NSFileManager *)fileManager {
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

- (BOOL)createDir:(NSString *)dir inDir:(NSString *)inDir {
    NSString *path = [NSString stringWithFormat:@"%@/%@", inDir, dir];
    BOOL isDir;
    if (![self.fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        BOOL res = [self.fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        return res;
    } else {
        return NO;
    }
}

- (BOOL)createFile:(NSString *)name inDir:(NSString *)inDir {
    NSString *path = [NSString stringWithFormat:@"%@/%@", inDir, name];
    if ([self.fileManager fileExistsAtPath:path]) {
        BOOL res = [self.fileManager createFileAtPath:path contents:nil attributes:nil];
        return res;
    } else {
        return NO;
    }
}

- (NSDictionary *)fileAttriutes:(NSString *)path {
    NSDictionary *fileAttriutes = [self.fileManager attributesOfItemAtPath:path error:nil];
    return fileAttriutes;
}

- (BOOL)deleteFileByPath:(NSString *)path {
    return [self.fileManager removeItemAtPath:path error:nil];
}

- (BOOL)copyFile:(NSString *)path toPath:(NSString *)toPath {
    BOOL res = NO;
    NSError *error = nil;
    
    res = [self.fileManager copyItemAtPath:path toPath:toPath error:&error];
    if (error) {
        NSLog(@"copy失败：%@", [error localizedDescription]);
    }
    return res;
}

- (BOOL)cutFile:(NSString *)path toPath:(NSString *)toPath {
    BOOL res = NO;
    NSError *error = nil;
    
    res = [self.fileManager moveItemAtPath:path toPath:toPath error:&error];
    if (error) {
        NSLog(@"cut失败：%@", [error localizedDescription]);
    }
    return res;
}

- (NSMutableArray *)getAllFileByPath:(NSString *)path {
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:[self.fileManager contentsOfDirectoryAtPath:path error:nil]];
    return array;
}

- (NSMutableArray *)getAllFolderByPath:(NSString *)path {
    NSMutableArray *filePathList = [self getAllFileByPath:path];
    NSMutableArray *folderPathList = [[NSMutableArray alloc] init];
    
    for (NSString *p in filePathList) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, p];
        NSString *fileType = [[self.fileManager attributesOfItemAtPath:fullPath error:NULL] fileType];
        if ([fileType isEqualToString:NSFileTypeDirectory]) {
            [folderPathList addObject:fullPath];
        }
    }
    
    return folderPathList;
}

- (NSMutableArray *)getAllImagesByPath:(NSString *)path {
    NSMutableArray *filePathList = [self getAllFileByPath:path];
    NSMutableArray *imagesPathList = [[NSMutableArray alloc] init];
    
    for (NSString *p in filePathList) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, p];
        FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeByPath:fullPath];
        if (fileType == FileType_img) {
            [imagesPathList addObject:fullPath];
        }
    }
    
    return imagesPathList;
}

- (NSMutableArray *)getAllImagesInPathArray:(NSMutableArray *)array withPath:(NSString *)path {
    NSMutableArray *imagesPathList = [[NSMutableArray alloc] init];
    
    for (NSString *p in array) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, p];
        FileType fileType = [[HcdFileManager sharedHcdFileManager] getFileTypeByPath:fullPath];
        if (fileType == FileType_img) {
            [imagesPathList addObject:fullPath];
        }
    }
    
    return imagesPathList;
}

- (float)sizeOfPath:(NSString *)path {
    if (![self.fileManager fileExistsAtPath:path]) {
        return 0.0;
    }
    NSDictionary *attributes = [self.fileManager attributesOfItemAtPath:path error:NULL];
    NSString *fileType = [attributes fileType];
    if ([fileType isEqualToString:NSFileTypeDirectory]) {
        return [self folderSizeAtPath:path];
    } else {
        return [self fileSizeAtPath:path];
    }
}

- (long long)fileSizeAtPath:(NSString *) filePath {
    if ([self.fileManager fileExistsAtPath:filePath]) {
        return [[self.fileManager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

- (long long)folderSizeAtPath:(NSString*) folderPath {
    if (![self.fileManager fileExistsAtPath:folderPath]) {
        return 0;
    }
    
    NSEnumerator *childFilesEnumerator = [[self.fileManager subpathsAtPath:folderPath] objectEnumerator];
    NSString *fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil) {
        NSString *fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    return folderSize;
}

- (BOOL)renameFileName:(NSString *)oldName newName:(NSString *)newName inPath:(nonnull NSString *)path {
    BOOL res = NO;
    NSError * error = nil;
    
    res = [self.fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@", path, oldName] toPath:[NSString stringWithFormat:@"%@/%@", path, newName] error:&error];
    if (error) {
        NSLog(@"rename失败：%@", [error localizedDescription]);
    }
    return res;
}

- (FileType)getFileTypeByPath:(NSString *)path {
    FileType fileType = FileType_unkonwn;
    
    if ([self.fileManager fileExistsAtPath:path]) {
        NSDictionary *attributes = [self.fileManager attributesOfItemAtPath:path error:NULL];
        NSString *type = [attributes fileType];
        if ([type isEqualToString:NSFileTypeDirectory]) {
            fileType = FileType_file_dir;
        } else {
            NSString *suffix = [[path pathExtension] lowercaseString];
            
            fileType = [self getFileTypeBySuffix:suffix];
        }
    }
    
    return fileType;
}

- (FileType)getFileTypeBySuffix:(NSString *)suffix {
    FileType fileType = FileType_unkonwn;
    if ([suffix isEqualToString:@"apk"]) {
        fileType = FileType_apk;
    } else if ([suffix isEqualToString:@"ipa"]) {
        fileType = FileType_ipa;
    } else if ([@[@"doc", @"docx", @"pages"] containsObject:suffix]) {
        fileType = FileType_doc;
    } else if ([@[@"html", @"htm"] containsObject:suffix]) {
        fileType = FileType_html;
    } else if ([@[@"mp3", @"wma", @"wav", @"ape", @"flac"] containsObject:suffix]) {
        fileType = FileType_music;
    } else if ([@[@"pdf"] containsObject:suffix]) {
        fileType = FileType_pdf;
    } else if ([@[@"ppt", @"pptx", @"key"] containsObject:suffix]) {
        fileType = FileType_ppt;
    } else if ([@[@"torrent"] containsObject:suffix]) {
        fileType = FileType_torrent;
    } else if ([@[@"txt"] containsObject:suffix]) {
        fileType = FileType_txt;
    } else if ([@[@"vcf"] containsObject:suffix]) {
        fileType = FileType_vcf;
    } else if ([@[@"mp4", @"avi", @"mov", @"asf", @"asx", @"wmv", @"mkv", @"3gp", @"rmvb", @"vob", @"dat", @"webm", @"hevc", @"m4v", @"flv", @"ogv", @"ts", @"mpg", @"mpeg", @"rm", @"ram", @"swf", @"mpe", @"mpa", @"m15", @"m1v", @"mp2", @"dmv", @"amv", @"mtv"] containsObject:suffix]) {
        fileType = FileType_video;
    } else if ([@[@"vsd"] containsObject:suffix]) {
        fileType = FileType_vsd;
    } else if ([@[@"xls", @"xlsx", @"numbers"] containsObject:suffix]) {
        fileType = FileType_xls;
    } else if ([@[@"jpg", @"jpeg", @"png", @"bmp", @"svg", @"psd", @"ai", @"webp", @"wmf", @"pcx"] containsObject:suffix]) {
        fileType = FileType_img;
    } else if ([@[@"zip", @"rar", @"7z", @"jar", @"kz", @"zipx", @"zz", @"exe"] containsObject:suffix]) {
        fileType = FileType_zip;
    }
    return fileType;
}

- (UIImage *)getFileTypeImageByPath:(NSString *)path {
    
    FileType type = [self getFileTypeByPath:path];
    
    return [self getFileTypeImageByFileType:type];
}

- (UIImage *)getFileTypeImageByFileType:(FileType)type {
    
    NSString *typeStr = @"unkonwn";
    
    switch (type) {
        case FileType_unkonwn:
            typeStr = @"unkonwn";
            break;
        case FileType_apk:
            typeStr = @"apk";
            break;
        case FileType_doc:
            typeStr = @"doc";
            break;
        case FileType_file_dir:
            typeStr = @"file_dir";
            break;
        case FileType_html:
            typeStr = @"html";
            break;
        case FileType_img:
            typeStr = @"img";
            break;
        case FileType_ipa:
            typeStr = @"ipa";
            break;
        case FileType_music:
            typeStr = @"music";
            break;
        case FileType_pdf:
            typeStr = @"pdf";
            break;
        case FileType_ppt:
            typeStr = @"ppt";
            break;
        case FileType_torrent:
            typeStr = @"torrent";
            break;
        case FileType_txt:
            typeStr = @"txt";
            break;
        case FileType_vcf:
            typeStr = @"vcf";
            break;
        case FileType_video:
            typeStr = @"vedio";
            break;
        case FileType_vsd:
            typeStr = @"vsd";
            break;
        case FileType_xls:
            typeStr = @"xls";
            break;
        case FileType_zip:
            typeStr = @"zip";
            break;
        default:
            typeStr = @"unkonwn";
            break;
    }
    
    return [UIImage imageNamed:[NSString stringWithFormat:@"hcdplayer.bundle/barcode_result_page_type_%@_icon.png", typeStr]];
}

- (NSString *)getFileSizeStrByPath:(NSString *)path {
    double size = [self sizeOfPath:path];
    
    return [self formatSizeToStr:size];
}

- (NSString *)formatSizeToStr:(double)size {
    NSArray *sizeArr = @[@"B", @"KB", @"MB", @"GB"];
    
    NSString *str = nil;
    
    NSInteger i = 0;
    
    if (size < 1000) {
        str = [NSString stringWithFormat:@"%.2f%@", size, sizeArr[i]];
    }
    
    while (size > 1000 && i < [sizeArr count]) {
        size = size / 1000;
        i++;
        str = [NSString stringWithFormat:@"%.2f%@", size, sizeArr[i]];
    }
    
    return str;
}

- (NSDictionary *)getFileInfoByPath:(NSString *)path {
    if ([self.fileManager fileExistsAtPath:path]) {
        return [self.fileManager attributesOfItemAtPath:path error:nil];
    }
    return nil;
}

- (BOOL)fileExists:(NSString *)path {
    return [self.fileManager fileExistsAtPath:path];
}

@end
