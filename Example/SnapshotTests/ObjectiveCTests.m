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

@import AccessibilitySnapshot;
@import FBSnapshotTestCase;
@import XCTest;


@interface ObjectiveCTests : FBSnapshotTestCase

@end


@implementation ObjectiveCTests

- (void)setUp;
{
    [super setUp];

    self.fileNameOptions = FBSnapshotTestCaseFileNameIncludeOptionOS | FBSnapshotTestCaseFileNameIncludeOptionScreenSize | FBSnapshotTestCaseFileNameIncludeOptionScreenScale;
    self.recordMode = NO;
}

- (void)testSimpleView;
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, 150, 30)];
    label.text = @"Objective-C Snapshot";
    label.textColor = [UIColor redColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];

    SnapshotVerifyAccessibility(view, nil);
}

- (void)testSimpleViewWithIdentifier;
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, 150, 30)];
    label.text = @"Objective-C Snapshot";
    label.textColor = [UIColor redColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];

    SnapshotVerifyAccessibility(view, @"identifier");
}

- (void)testSimpleViewWithActivationPointDefault;
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, 150, 30)];
    label.text = @"Objective-C Snapshot";
    label.textColor = [UIColor redColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    label.accessibilityActivationPoint = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 2 - 10);

    SnapshotVerifyAccessibility(view, nil);
}

- (void)testSimpleViewWithActivationPointAlways;
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, 150, 30)];
    label.text = @"Objective-C Snapshot";
    label.textColor = [UIColor redColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];

    SnapshotVerifyAccessibilityWithOptions(view, nil, YES, YES, NO);
}

- (void)testSimpleViewWithActivationPointNever;
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, 150, 30)];
    label.text = @"Objective-C Snapshot";
    label.textColor = [UIColor redColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    label.accessibilityActivationPoint = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 2 - 10);

    SnapshotVerifyAccessibilityWithOptions(view, nil, NO, YES, NO);
}

- (void)testSimpleViewWithColorSnapshots;
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 50)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 10, 150, 30)];
    label.text = @"Objective-C Snapshot";
    label.textColor = [UIColor redColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    [view addSubview:label];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    label.accessibilityActivationPoint = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 2 - 10);

    SnapshotVerifyAccessibilityWithOptions(view, nil, NO, NO, NO);
}

- (void)testViewWithInvertedColors;
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [view setBackgroundColor:[UIColor redColor]];

    UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(25, 25, 50, 50)];
    [subview setBackgroundColor:[UIColor greenColor]];

    [subview setAccessibilityIgnoresInvertColors:YES];
    [view addSubview:subview];

    SnapshotVerifyWithInvertedColors(view, nil);
}

- (void)testHitTargets;
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    [view setBackgroundColor:[UIColor whiteColor]];

    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 25, 100, 50)];
    [button setBackgroundColor:[UIColor redColor]];
    [view addSubview:button];

    SnapshotVerifyWithHitTargets(view, nil, YES, 1, 1);
}

@end
