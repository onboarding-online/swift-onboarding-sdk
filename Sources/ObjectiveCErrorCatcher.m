//
//  ObjectiveCErrorCatcher.m
//  
//
//  Created by Leonid Yuriev on 28.05.25.
//
#import "ObjectiveCErrorCatcher.h"

@implementation ObjectiveCErrorCatcher

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        if (error != NULL) { // Добавлена проверка на NULL, чтобы избежать разыменования нулевого указателя
            *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        }
        return NO;
    }
}

@end
