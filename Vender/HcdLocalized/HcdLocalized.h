//
//  HcdLocalized.h
//  HcdPlayer
//
//  Created by Salvador on 2019/1/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    HcdLanguageChineseSimple,
    HcdLanguageChineseTraditional,
    HcdLanguageEnglish,
    HcdLanguageCount
} HcdLanguage;

NS_ASSUME_NONNULL_BEGIN

//语言切换
static NSString * const AppLanguage = @"appLanguage";
#define HcdLocalized(key, comment)  [[NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:AppLanguage]] ofType:@"lproj"]] localizedStringForKey:(key) value:@"" table:nil]

@interface HcdLocalized : NSObject

+ (HcdLocalized *)sharedInstance;

//初始化多语言功能
- (void)initLanguage;

//当前语言
- (NSString *)currentLanguageStr;

//设置要转换的语言
- (void)setLanguage:(NSString *)language;

//设置为系统语言
- (void)systemLanguage;

- (HcdLanguage)currentLanguage;

@end

NS_ASSUME_NONNULL_END
