#define SnapshotImpreciseVerifyAccessibility(view__, identifier__, perPixelTolerance__, overallTolerance__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyAccessibility:identifier:perPixelTolerance:overallTolerance:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *, CGFloat, CGFloat);\
        SnapshotMethod snapshotVerifyAccessibility = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyAccessibility(self, selector, view__, identifier__ ?: @"", perPixelTolerance__, overallTolerance__);\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }

#define SnapshotImpreciseVerifyAccessibilityWithOptions(view__, identifier__, showActivationPoints__, useMonochromeSnapshot__, perPixelTolerance__, overallTolerance__, showUserInputLabels__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyAccessibility:identifier:showActivationPoints:useMonochromeSnapshot:perPixelTolerance:overallTolerance:showUserInputLabels:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *, BOOL, BOOL, CGFloat, CGFloat, BOOL);\
        SnapshotMethod snapshotVerifyAccessibility = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyAccessibility(self, selector, view__, identifier__ ?: @"", showActivationPoints__, useMonochromeSnapshot__, perPixelTolerance__, overallTolerance__, showUserInputLabels__);\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }

#define SnapshotImpreciseVerifyWithInvertedColors(view__, identifier__, perPixelTolerance__, overallTolerance__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyWithInvertedColors:identifier:perPixelTolerance:overallTolerance:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *, CGFloat, CGFloat);\
        SnapshotMethod snapshotVerifyWithInvertedColors = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyWithInvertedColors(self, selector, view__, identifier__ ?: @"", perPixelTolerance__, overallTolerance__);\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }

#define SnapshotImpreciseVerifyWithHitTargets(view__, identifier__, useMonochromeSnapshot__, maxPermissibleMissedRegionWidth__, maxPermissibleMissedRegionHeight__, perPixelTolerance__, overallTolerance__)\
    {\
        _Pragma("clang diagnostic push")\
        _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")\
        SEL selector = @selector(snapshotVerifyWithHitTargets:identifier:useMonochromeSnapshot:maxPermissibleMissedRegionWidth:maxPermissibleMissedRegionHeight:perPixelTolerance:overallTolerance:);\
        _Pragma("clang diagnostic pop")\
        typedef NSString * (*SnapshotMethod)(id, SEL, UIView *, NSString *, BOOL, CGFloat, CGFloat, CGFloat, CGFloat);\
        SnapshotMethod snapshotVerifyWithHitTargets = (SnapshotMethod)[self methodForSelector:selector];\
        NSString *errorDescription = snapshotVerifyWithHitTargets(self, selector, view__, identifier__ ?: @"", useMonochromeSnapshot__, maxPermissibleMissedRegionWidth__, maxPermissibleMissedRegionHeight__, perPixelTolerance__, overallTolerance__);\
        if (errorDescription == nil) {\
            XCTAssertTrue(YES);\
        } else {\
            XCTFail("%@", errorDescription);\
        }\
    }
