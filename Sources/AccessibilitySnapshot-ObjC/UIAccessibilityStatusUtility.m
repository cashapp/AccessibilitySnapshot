//
//  Copyright 2019 Square Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "include/UIAccessibilityStatusUtility.h"

@import fishhook;

#import <dlfcn.h>

@interface UIAccessibilityStatusUtility ()

@property (nonatomic) NSMutableArray<NSValue *> *rerebindings;

@end

@implementation UIAccessibilityStatusUtility

- (instancetype)init;
{
    if (self = [super init]) {
        _rerebindings = [NSMutableArray<NSValue *> new];
    }
    return self;
}

- (void)mockInvertColorsStatus;
{
    [self mockStatusForFunction:&UIAccessibilityIsInvertColorsEnabled
                          named:"UIAccessibilityIsInvertColorsEnabled"];
}

- (void)mockStatusForFunction:(void *)function named:(const char *)functionName;
{
    struct rebinding rerebinding = {functionName, function, NULL};
    [self.rerebindings addObject:[NSValue valueWithBytes:&rerebinding
                                                objCType:@encode(struct rebinding)]];

    struct rebinding rebindings[] = {{
        functionName,
        &UIAccessibilityAlwaysEnabled,
        NULL
    }};
    
    rebind_symbols(rebindings, 1); // !!
}

- (void)unmockStatuses;
{
    for (NSValue *rebindingValue in self.rerebindings) {
        struct rebinding rebinding;
        [rebindingValue getValue:&rebinding];

        rebind_symbols((struct rebinding[1]){rebinding}, 1); // !!
    }

    [self.rerebindings removeAllObjects];
}

BOOL UIAccessibilityAlwaysEnabled() {
    return true;
}

@end
