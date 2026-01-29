@import FBSnapshotTestCase_Accessibility_ObjC;
@import iOSSnapshotTestCaseCore;
@import XCTest;


@interface ImpreciseObjectiveCTests : FBSnapshotTestCase

@end


@implementation ImpreciseObjectiveCTests

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

    SnapshotImpreciseVerifyAccessibility(view, nil, 0, 0);
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

    SnapshotImpreciseVerifyAccessibility(view, @"identifier", 0, 0);
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

    SnapshotImpreciseVerifyAccessibilityWithOptions(view, nil, YES, YES, 0, 0, NO);
}

- (void)testViewWithInvertedColors;
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [view setBackgroundColor:[UIColor redColor]];

    UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(25, 25, 50, 50)];
    [subview setBackgroundColor:[UIColor greenColor]];

    [subview setAccessibilityIgnoresInvertColors:YES];
    [view addSubview:subview];

    SnapshotImpreciseVerifyWithInvertedColors(view, nil, 0, 0);
}

@end
