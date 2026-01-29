@import AccessibilitySnapshotParser_ObjC;
@import XCTest;


@interface UIAccessibilityStatusUtilityObjCTests : XCTestCase

@end


@implementation UIAccessibilityStatusUtilityObjCTests

- (void)testInvertColorsStatus;
{
    UIAccessibilityStatusUtility *const statusUtility = [UIAccessibilityStatusUtility new];

    XCTAssertFalse(UIAccessibilityIsInvertColorsEnabled());

    [statusUtility mockInvertColorsStatus];
    XCTAssertTrue(UIAccessibilityIsInvertColorsEnabled());

    [statusUtility unmockStatuses];
    XCTAssertFalse(UIAccessibilityIsInvertColorsEnabled());
}

@end
