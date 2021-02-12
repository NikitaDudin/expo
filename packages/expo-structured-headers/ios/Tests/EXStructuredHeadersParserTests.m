//  Copyright (c) 2021 650 Industries, Inc. All rights reserved.

@import XCTest;

#import <objc/runtime.h>
#import <EXStructuredHeaders/EXStructuredHeadersParser.h>

#import "EXStructuredHeadersTestFixtures.h"
#import "NSArray+EXStructuredHeadersTests.h"
#import "NSDictionary+EXStructuredHeadersTests.h"

@interface EXStructuredHeadersParserTests : XCTestCase

@end

@implementation EXStructuredHeadersParserTests

- (void)setUp
{
  [super setUp];

  // Replace NSDictionary's isEqual: method at runtime with one that knows about
  // the idiomatic format of the `expected` field in the test JSON objects.
  // This prevents us from having to iterate through every possible item and
  // pre-process the expected objects.
  //
  // Same for NSArray, since dictionaries are represented in the expected results
  // as arrays of tuples rather than key-value objects.
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self swizzleMethodForClass:[NSDictionary class]];
    [self swizzleMethodForClass:[NSArray class]];
  });
}

- (void)tearDown
{
  [super tearDown];
}

// https://nshipster.com/method-swizzling/
- (void)swizzleMethodForClass:(Class)class
{
  SEL originalSelector = @selector(isEqual:);
  SEL swizzledSelector = @selector(isEqualToTestResult:);

  Method originalMethod = class_getInstanceMethod(class, originalSelector);
  Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
  
  BOOL didAddMethod =
  class_addMethod(class,
                  originalSelector,
                  method_getImplementation(swizzledMethod),
                  method_getTypeEncoding(swizzledMethod));
  
  if (didAddMethod) {
    class_replaceMethod(class,
                        swizzledSelector,
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
  } else {
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
}

- (void)runTests:(NSString *)testsJson
{
  NSError *error;
  NSArray<NSDictionary *> *tests = [NSJSONSerialization JSONObjectWithData:[testsJson dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
  XCTAssertNil(error);

  XCTAssert(tests.count > 0, @"There should be at least one test");

  for (NSDictionary *test in tests) {
    // When generating input_bytes, parsers MUST combine all field lines in the same section (header or trailer)
    // that case-insensitively match the field name into one comma-separated field-value, as per [RFC7230], Section 3.2.2;
    // this assures that the entire field value is processed correctly.
    NSString *rawInput = [(NSArray *)test[@"raw"] componentsJoinedByString:@","];
    EXStructuredHeadersParser *parser = [[EXStructuredHeadersParser alloc] initWithRawInput:rawInput fieldType:[self fieldTypeWithString:test[@"header_type"]]];
    if ([(NSNumber *)test[@"must_fail"] boolValue]) {
      NSError *error;
      XCTAssertNil([parser parseStructuredFieldsWithError:&error], @"Test failed: %@", test[@"name"]);
      XCTAssertNotNil(error, @"Test failed correctly, but there was no error object: %@", test[@"name"]);
    } else {
      NSError *error;
      id actual = [parser parseStructuredFieldsWithError:&error];
      XCTAssertNil(error, @"Test failed: %@", test[@"name"]);

      id expected = test[@"expected"];
      if ([(NSNumber *)test[@"can_fail"] boolValue]) {
        XCTAssert(!actual || [expected isEqual:actual], @"Test failed: %@", test[@"name"]);
      } else {
        XCTAssertEqualObjects(expected, actual, @"Test failed: %@", test[@"name"]);
      }
    }
  }
}

- (EXStructuredHeadersParserFieldType)fieldTypeWithString:(NSString *)string
{
  if ([@"dictionary" isEqualToString:string]) {
    return EXStructuredHeadersParserFieldTypeDictionary;
  } else if ([@"list" isEqualToString:string]) {
    return EXStructuredHeadersParserFieldTypeList;
  } else if ([@"item" isEqualToString:string]) {
    return EXStructuredHeadersParserFieldTypeItem;
  } else {
    XCTAssert(NO, @"unexpected header_type");
  }
}

// do not modify below this line - generated by scripts/generated-tests.js

// GENERATED TESTS BEGIN

- (void)testBinary
{
  [self runTests:EXStructuredHeadersBinaryTests];
}

- (void)testBoolean
{
  [self runTests:EXStructuredHeadersBooleanTests];
}

- (void)testDictionary
{
  [self runTests:EXStructuredHeadersDictionaryTests];
}

- (void)testExamples
{
  [self runTests:EXStructuredHeadersExamplesTests];
}

- (void)testItem
{
  [self runTests:EXStructuredHeadersItemTests];
}

- (void)testKeyGenerated
{
  [self runTests:EXStructuredHeadersKeyGeneratedTests];
}

- (void)testLargeGenerated
{
  [self runTests:EXStructuredHeadersLargeGeneratedTests];
}

- (void)testList
{
  [self runTests:EXStructuredHeadersListTests];
}

- (void)testListlist
{
  [self runTests:EXStructuredHeadersListlistTests];
}

- (void)testNumberGenerated
{
  [self runTests:EXStructuredHeadersNumberGeneratedTests];
}

- (void)testNumber
{
  [self runTests:EXStructuredHeadersNumberTests];
}

- (void)testParamDict
{
  [self runTests:EXStructuredHeadersParamDictTests];
}

- (void)testParamList
{
  [self runTests:EXStructuredHeadersParamListTests];
}

- (void)testParamListlist
{
  [self runTests:EXStructuredHeadersParamListlistTests];
}

- (void)testStringGenerated
{
  [self runTests:EXStructuredHeadersStringGeneratedTests];
}

- (void)testString
{
  [self runTests:EXStructuredHeadersStringTests];
}

- (void)testTokenGenerated
{
  [self runTests:EXStructuredHeadersTokenGeneratedTests];
}

- (void)testToken
{
  [self runTests:EXStructuredHeadersTokenTests];
}

@end
