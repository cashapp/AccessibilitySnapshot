//
//  ObjectiveCTests.m
//  HeadlessSnapshotTests
//
//  Created by Nicholas Entin on 5/20/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

@import AccessibilitySnapshot;
@import FBSnapshotTestCase;
@import XCTest;


@interface ObjectiveCTests : FBSnapshotTestCase

@end


@implementation ObjectiveCTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    UIView *view = [UIView new];
    SnapshotVerifyAccessibility(view, nil);
}

@end
