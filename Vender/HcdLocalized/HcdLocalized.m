//
//  HcdLocalized.m
//  HcdPlayer
//
//  Created by Salvador on 2019/1/19.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdLocalized.h"

@implementation HcdLocalized
+ (HcdLocalized *)sharedInstance{
    static HcdLocalized *language=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        language = [[HcdLocalized alloc] init];
    });
    return language;
}

- (void)initLanguage{
    NSString *language=[self currentLanguageStr];
    if (language.length>0) {
        NSLog(@"自设置语言:%@",language);
    }else{
        [self systemLanguage];
    }
}

- (NSString *)currentLanguageStr{
    NSString *languageCode=[[NSUserDefaults standardUserDefaults]objectForKey:AppLanguage];
    if ([languageCode hasPrefix:@"zh-Hans"]) {
        return HcdLocalized(@"chineseSimple", nil);
    } else if ([languageCode hasPrefix:@"zh-Hant"]) {
        return HcdLocalized(@"chineseTraditional", nil);
    } else if ([languageCode hasPrefix:@"en"]) {
        return HcdLocalized(@"english", nil);
    } else {
        return HcdLocalized(@"english", nil);
    }
}

- (HcdLanguage)currentLanguage {
    NSString *languageCode = [[NSUserDefaults standardUserDefaults]objectForKey:AppLanguage];
    if ([languageCode hasPrefix:@"zh-Hans"]) {
        return HcdLanguageChineseSimple;
    } else if ([languageCode hasPrefix:@"zh-Hant"]) {
        return HcdLanguageChineseTraditional;
    } else if ([languageCode hasPrefix:@"en"]) {
        return HcdLanguageEnglish;
    } else {
        return HcdLanguageEnglish;
    }
}

- (void)setLanguage:(NSString *)language{
    [[NSUserDefaults standardUserDefaults] setObject:language forKey:AppLanguage];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)systemLanguage{
    NSString *languageCode = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"][0];
    NSLog(@"系统语言:%@",languageCode);
    if([languageCode hasPrefix:@"zh-Hant"]){
        languageCode = @"zh-Hant";//繁体中文
    }else if([languageCode hasPrefix:@"zh-Hans"]){
        languageCode = @"zh-Hans";//简体中文
    }else if([languageCode hasPrefix:@"pt"]){
        languageCode = @"pt";//葡萄牙语
    }else if([languageCode hasPrefix:@"es"]){
        languageCode = @"es";//西班牙语
    }else if([languageCode hasPrefix:@"th"]){
        languageCode = @"th";//泰语
    }else if([languageCode hasPrefix:@"hi"]){
        languageCode = @"hi";//印地语
    }else if([languageCode hasPrefix:@"ru"]){
        languageCode = @"ru";//俄语
    }else if([languageCode hasPrefix:@"ja"]){
        languageCode = @"ja";//日语
    }else if([languageCode hasPrefix:@"en"]){
        languageCode = @"en";//英语
    }else{
        languageCode = @"en";//英语
    }
    [self setLanguage:languageCode];
}
/*  升级ios9之后，使得原本支持中英文的app出现闪退，中英文混乱的问题！大家不要慌，原因是升级之后中英文目录名字改了。在真机上，中文资源目录名由zh-Hans---->zh-Hans-CN，英文资源目录名由en---->en-CN，ios9模拟器上面的中英文资源目录名和真机上面的不一样，分别是zh-Hans-US，en-US。
 */

@end
