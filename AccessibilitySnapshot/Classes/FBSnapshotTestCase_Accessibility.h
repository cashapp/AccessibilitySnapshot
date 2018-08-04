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

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>

#define SnapshotVerifyAccessibility(view__, identifier__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyAccessibility:identifier:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *);\
        SnapshotMethod snapshotVerifyAccessibility = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyAccessibility(self, selector, view__, identifier__ ?: @"");\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }

#define SnapshotVerifyAccessibilityWithActivationPoints(view__, identifier__, showActivationPoints__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyAccessibility:identifier:showActivationPoints:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *, BOOL);\
        SnapshotMethod snapshotVerifyAccessibility = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyAccessibility(self, selector, view__, identifier__ ?: @"", showActivationPoints__);\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }

#define SnapshotVerifyWithInvertedColors(view__, identifier__)\
    {\
        if (@available(iOS 11.0, *)) {\
            _Pragma("clang diagnostic push")\
            _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
            SEL selector = @selector(snapshotVerifyWithInvertedColors:identifier:);\
            _Pragma("clang diagnostic pop")\
            typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *);\
            SnapshotMethod snapshotVerifyWithInvertedColors = (SnapshotMethod)[self methodForSelector:selector];\
            NSString *errorDescription = snapshotVerifyWithInvertedColors(self, selector, view__, identifier__ ?: @"");\
            if (errorDescription == nil) {\
                XCTAssertTrue(YES);\
            } else {\
                XCTFail("%@", errorDescription);\
            }\
        } else {\
            XCTFail(@"Snapshot testing with inverted colors is only available on iOS 11 and greater.");\
        }\
    }
