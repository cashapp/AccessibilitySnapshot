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

#import "include/UIView+DynamicTypeSnapshotting.h"

#import <objc/runtime.h>

#import "UIApplication+DynamicTypeSnapshotting.h"

@protocol UIViewTraitProcessing

- (void)_processDidChangeRecursivelyFromOldTraits:(UITraitCollection *)oldTraits toCurrentTraits:(UITraitCollection *)currentTraits forceNotification:(BOOL)forceNotification;

@end

@implementation UIView (DynamicTypeSnapshotting)

static UIContentSizeCategory contentSizeCategoryOverride = nil;

+ (void)load;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(traitCollection);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);

        SEL swizzledSelector = @selector(AS_traitCollection);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

+ (void)AS_setPreferredContentSizeCategoryOverride:(nullable UIContentSizeCategory)contentSizeCategory;
{
    contentSizeCategoryOverride = contentSizeCategory;

    [UIApplication AS_setPreferredContentSizeCategoryOverride:contentSizeCategory];
}

- (UITraitCollection *)AS_traitCollection;
{
    UITraitCollection *traitCollection = [self AS_traitCollection];

    if (contentSizeCategoryOverride != nil) {
        UITraitCollection *contentSizeCategoryTraitCollection = [UITraitCollection traitCollectionWithPreferredContentSizeCategory:contentSizeCategoryOverride];
        return [UITraitCollection traitCollectionWithTraitsFromCollections:@[traitCollection, contentSizeCategoryTraitCollection]];

    } else {
        return traitCollection;
    }
}

- (void)AS_processChangeFromTraits:(UITraitCollection *)oldTraits;
{
    SEL selector = @selector(_processDidChangeRecursivelyFromOldTraits:toCurrentTraits:forceNotification:);
    typedef void (*ProcessChangeMethod)(id, SEL, UITraitCollection *, UITraitCollection *, BOOL);
    ProcessChangeMethod processChange = (ProcessChangeMethod)[self methodForSelector:selector];
    processChange(self, selector, oldTraits, [self traitCollection], YES);
}

@end
