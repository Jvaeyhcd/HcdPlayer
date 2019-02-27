//
//  HcdDocument.m
//  HcdPlayer
//
//  Created by Salvador on 2019/2/27.
//  Copyright © 2019 Salvador. All rights reserved.
//

#import "HcdDocument.h"

@implementation HcdDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
    self.data = contents;
    return YES;
}

@end
