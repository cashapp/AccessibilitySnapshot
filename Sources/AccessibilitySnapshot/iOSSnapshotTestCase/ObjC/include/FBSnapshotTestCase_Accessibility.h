//
//  Copyright 2024 Block Inc.
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

#define SnapshotVerifyAccessibility(view__, identifier__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyAccessibility:identifier:perPixelTolerance:overallTolerance:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *, CGFloat, CGFloat);\
        SnapshotMethod snapshotVerifyAccessibility = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyAccessibility(self, selector, view__, identifier__ ?: @"", 0, 0);\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }

#define SnapshotVerifyAccessibilityWithOptions(view__, identifier__, showActivationPoints__, useMonochromeSnapshot__, showUserInputLabels__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyAccessibility:identifier:showActivationPoints:useMonochromeSnapshot:perPixelTolerance:overallTolerance:showUserInputLabels:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *, BOOL, BOOL, CGFloat, CGFloat, BOOL);\
        SnapshotMethod snapshotVerifyAccessibility = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyAccessibility(self, selector, view__, identifier__ ?: @"", showActivationPoints__, useMonochromeSnapshot__, 0, 0, showUserInputLabels__);\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }

#define SnapshotVerifyWithInvertedColors(view__, identifier__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyWithInvertedColors:identifier:perPixelTolerance:overallTolerance:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *, CGFloat, CGFloat);\
        SnapshotMethod snapshotVerifyWithInvertedColors = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyWithInvertedColors(self, selector, view__, identifier__ ?: @"", 0, 0);\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }

#define SnapshotVerifyWithHitTargets(view__, identifier__, useMonochromeSnapshot__, maxPermissibleMissedRegionWidth__, maxPermissibleMissedRegionHeight__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyWithHitTargets:identifier:useMonochromeSnapshot:maxPermissibleMissedRegionWidth:maxPermissibleMissedRegionHeight:perPixelTolerance:overallTolerance:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *, BOOL, CGFloat, CGFloat, CGFloat, CGFloat);\
        SnapshotMethod snapshotVerifyWithHitTargets = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyWithHitTargets(self, selector, view__, identifier__ ?: @"", useMonochromeSnapshot__, maxPermissibleMissedRegionWidth__, maxPermissibleMissedRegionHeight__, 0, 0);\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }
