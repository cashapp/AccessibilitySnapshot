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

#import "UIApplication+DynamicTypeSnapshotting.h"

#import <objc/runtime.h>

@implementation UIApplication (DynamicTypeSnapshotting)

static UIContentSizeCategory contentSizeCategoryOverride = nil;

+ (void)load;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(preferredContentSizeCategory);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);

        SEL swizzledSelector = @selector(AS_preferredContentSizeCategory);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

+ (void)AS_setPreferredContentSizeCategoryOverride:(nullable UIContentSizeCategory)contentSizeCategory;
{
    contentSizeCategoryOverride = contentSizeCategory;
}

- (UIContentSizeCategory)AS_preferredContentSizeCategory;
{
    UIContentSizeCategory contentSizeCategory = [self AS_preferredContentSizeCategory];
    return contentSizeCategoryOverride ?: contentSizeCategory;
}

@end
