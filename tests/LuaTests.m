#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <XCTest/XCTest.h>

#import "LuaContext.h"
#import "LuaExport.h"

#if TARGET_OS_MAC
@interface NSValue (CGAddons)

+ (NSValue *)valueWithCGRect:(CGRect)rect;
- (CGRect)CGRectValue;

@end

@implementation NSValue (CGAddons)

+ (NSValue *)valueWithCGRect:(CGRect)rect {
    return [NSValue valueWithBytes:&rect objCType:@encode(CGRect)];
}

- (CGRect)CGRectValue {
    if( strcmp(@encode(CGRect), self.objCType) )
        return CGRectZero;
    CGRect rect;
    [self getValue:&rect];
    return rect;
}

@end

#endif

static inline BOOL compareFloatsEpsilon(float a, float b) {
    return fabs(a - b) < __FLT_EPSILON__;
}

@interface ExportObject : NSObject

@property (nonatomic, strong) NSString *privateString;
@property (nonatomic, strong) NSString *publicString;

@property (nonatomic, assign) CGFloat floatProperty;

@property (nonatomic, assign) BOOL silence;

- (NSString*)privateMethod;
- (NSString*)publicMethod;

- (void)voidTakesString:(NSString*)str andNumber:(NSNumber*)num;
- (CGRect)rectTakesArray:(NSArray*)arr andRect:(CGRect)rect;
- (CGFloat)floatTakesNothing;
- (CGAffineTransform)transformTakesTransform:(CGAffineTransform)transform andFloat:(CGFloat)fl;
- (NSArray*)transformTakesArray:(NSArray*)transform andFloat:(CGFloat)fl;

- (CATransform3D)passThroughMatrix:(CATransform3D)matrix;

@end

@interface InheritedExportObject : ExportObject


@property (nonatomic, strong) NSString *privateString2;
@property (nonatomic, strong) NSString *publicString2;

- (NSString*)privateMethod2;
- (NSString*)publicMethod2;

@end

@interface InheritedPrivateObject : InheritedExportObject


@property (nonatomic, strong) NSString *privateString3;

- (NSString*)privateMethod3;

@end

static inline NSString *StringFromCGRect(const CGRect rect) {
    return [NSString stringWithFormat:@"{ { %f x %f }, { %f x %f } }",
            rect.origin.x, rect.origin.y, rect.size.width, rect.size.height ];
}

static inline NSString *StringFromCGAffineTransform(const CGAffineTransform xform) {
    return [NSString stringWithFormat:@"{ { %f, %f }, { %f, %f }, { %f, %f } }",
            xform.a, xform.b, xform.c, xform.d, xform.tx, xform.ty];
}

static inline NSString *StringFromCATransform3D(const CATransform3D xform) {
    return [NSString stringWithFormat:@"{ { %f, %f, %f, %f }, { %f, %f, %f, %f }, { %f, %f, %f, %f }, { %f, %f, %f, %f } }",
            xform.m11, xform.m12, xform.m13, xform.m14,
            xform.m21, xform.m22, xform.m23, xform.m24,
            xform.m31, xform.m32, xform.m33, xform.m34,
            xform.m41, xform.m42, xform.m43, xform.m44 ];
}

static int ExportObjectInstanceCount = 0;    // See https://github.com/PedestrianSean/ObjC-Lua/issues/2

@implementation ExportObject

- (id)init {
    if( (self = [super init]) ) {
        _privateString = @"privateStr";
        _publicString = @"publicStr";
        ExportObjectInstanceCount += 1;
    }
    return self;
}

- (void)dealloc {
    ExportObjectInstanceCount -= 1;
}

- (NSString*)privateMethod {
    if( ! _silence )
        NSLog(@"private method called");
    return @"private method";
}

- (NSString*)publicMethod {
    if( ! _silence )
        NSLog(@"public method called");
    return @"public method";
}

- (void)voidTakesString:(NSString*)str andNumber:(NSNumber*)num {
    NSLog(@"%@ got: '%@' '%@'", NSStringFromSelector(_cmd), [str description], [num description]);
}

- (CGRect)rectTakesArray:(NSArray*)arr andRect:(CGRect)rect {
    NSLog(@"%@ got: '%@' '%@'", NSStringFromSelector(_cmd), [arr description], StringFromCGRect(rect));
    if( [arr count] == 4 )
        return CGRectMake([arr[0] floatValue], [arr[1] floatValue], [arr[2] floatValue], [arr[3] floatValue]);
    return rect;
}

- (CGFloat)floatTakesNothing {
    NSLog(@"%@ got: _", NSStringFromSelector(_cmd));
    return M_2_PI;
}

- (CGAffineTransform)transformTakesTransform:(CGAffineTransform)transform andFloat:(CGFloat)fl {
    NSLog(@"%@ got: '%@' '%f'", NSStringFromSelector(_cmd), StringFromCGAffineTransform(transform), fl);
    return CGAffineTransformRotate(transform, fl);
}

static inline CGAffineTransform CGAffineTransformFromArray(NSArray *transform) {
    if( [transform count] == 6 ) {
        CGAffineTransform xform = {
            [transform[0] floatValue], [transform[1] floatValue],
            [transform[2] floatValue], [transform[3] floatValue],
            [transform[4] floatValue], [transform[5] floatValue] };
        return xform;
    }
    return CGAffineTransformIdentity;
}

static inline CATransform3D CATransform3DFromArray(NSArray *transform) {
    if( [transform count] == 16 ) {
        CATransform3D xform = {
            [transform[0] floatValue], [transform[1] floatValue], [transform[2] floatValue], [transform[3] floatValue],
            [transform[4] floatValue], [transform[5] floatValue], [transform[6] floatValue], [transform[7] floatValue],
            [transform[8] floatValue], [transform[9] floatValue], [transform[10] floatValue], [transform[11] floatValue],
            [transform[12] floatValue], [transform[13] floatValue], [transform[14] floatValue], [transform[15] floatValue] };
        return xform;
    }
    return CATransform3DIdentity;
}

static inline NSArray* arrayFromCGAffineTransform(const CGAffineTransform xform) {
    return @[ @(xform.a), @(xform.b), @(xform.c), @(xform.d), @(xform.tx), @(xform.ty) ];
}

- (NSArray*)transformTakesArray:(NSArray*)transform andFloat:(CGFloat)fl {
    NSLog(@"%@ got: '%@' '%f'", NSStringFromSelector(_cmd), transform, fl);
    CGAffineTransform xform = CGAffineTransformFromArray(transform);
    xform = CGAffineTransformRotate(xform, fl);
    return arrayFromCGAffineTransform(xform);
}

- (CATransform3D)passThroughMatrix:(CATransform3D)matrix {
    NSLog(@"%@ got: '%@'", NSStringFromSelector(_cmd), StringFromCATransform3D(matrix));
    return matrix;
}

@end

@implementation InheritedExportObject

- (id)init {
    if( (self = [super init]) ) {
        _privateString2 = @"privateStr2";
        _publicString2 = @"publicStr2";
    }
    return self;
}

- (NSString*)privateMethod2 {
    if( ! self.silence )
        NSLog(@"private method 2 called");
    return @"private method 2";
}

- (NSString*)publicMethod2 {
    if( ! self.silence )
        NSLog(@"public method 2 called");
    return @"public method 2";
}

@end

@implementation InheritedPrivateObject

- (id)init {
    if( (self = [super init]) ) {
        _privateString3 = @"privateStr3";
    }
    return self;
}

- (NSString*)privateMethod3 {
    if( ! self.silence )
        NSLog(@"private method 3 called");
    return @"private method 3";
}

@end

@protocol ExportObjectExports <LuaExport>

@property (nonatomic, strong) NSString *publicString;

@property (nonatomic, assign) CGFloat floatProperty;

- (NSString*)publicMethod;

- (void)voidTakesString:(NSString*)str andNumber:(NSNumber*)num;
- (CGRect)rectTakesArray:(NSArray*)arr andRect:(CGRect)rect;
- (CGFloat)floatTakesNothing;
- (CGAffineTransform)transformTakesTransform:(CGAffineTransform)transform andFloat:(CGFloat)fl;
- (NSArray*)transformTakesArray:(NSArray*)transform andFloat:(CGFloat)fl;

- (CATransform3D)passThroughMatrix:(CATransform3D)matrix;

@end

@interface ExportObject (Exports) <ExportObjectExports>
@end
@implementation ExportObject (Exports)
@end

@protocol InheritedExportObjectExports <LuaExport>

@property (nonatomic, strong) NSString *publicString2;

- (NSString*)publicMethod2;

@end

@interface InheritedExportObject (Exports) <InheritedExportObjectExports>
@end
@implementation InheritedExportObject (Exports)
@end

@interface LuaTests : XCTestCase
@end

@implementation LuaTests

- (void)testValue {
    ExportObjectInstanceCount = 0; @autoreleasepool {

    LuaContext *ctx = [LuaContext new];

    NSError *error = nil;

    NSString *script = @"function say (n) print(n) return x end";
    [ctx parse:script error:&error];
    XCTAssert( ! error, @"failed to load script: %@", error);

    id result;

    ctx[@"x"] = @5;
    result = [ctx call:"say" with:@[ @"test int" ] error:&error];
    XCTAssert( ! error, @"failed to run say: %@", error);
    NSLog(@"say returned: %@", result);
    XCTAssert( [result intValue] == 5, @"result != 5");

    ctx[@"x"] = @M_PI;
    result = [ctx call:"say" with:@[ @"test float" ] error:&error];
    XCTAssert( ! error, @"failed to run say: %@", error);
    NSLog(@"say returned: %@", result);
    XCTAssert( [result doubleValue] == M_PI, @"result != Pi");

    ctx[@"x"] = @"string";
    result = [ctx call:"say" with:@[ @"test string" ] error:&error];
    XCTAssert( ! error, @"failed to run say: %@", error);
    NSLog(@"say returned: %@", result);
    XCTAssert( [result isEqualToString:@"string"], @"result != 'string'");

    ctx[@"x"] = @[ @3, @2, @1 ];
    result = [ctx call:"say" with:@[ @"test array" ] error:&error];
    XCTAssert( ! error, @"failed to run say: %@", error);
    NSLog(@"say returned: %@", result);
    XCTAssert( [result[0] intValue] == 3 && [result[1] intValue] == 2 && [result[2] intValue] == 1, @"result != 'string'");

    ctx[@"x"] = @{ @"a": @3, @"b": @2, @"c": @1 };
    result = [ctx call:"say" with:@[ @"test dictionary" ] error:&error];
    XCTAssert( ! error, @"failed to run say: %@", error);
    NSLog(@"say returned: %@", result);
    XCTAssert( [result[@"a"] intValue] == 3 && [result[@"b"] intValue] == 2 && [result[@"c"] intValue] == 1, @"result != 'string'");

    } XCTAssert( ExportObjectInstanceCount == 0, "ExportObject leak (%s): %d", __func__, ExportObjectInstanceCount);
}

static inline BOOL CGAffineTransformEqualToTransformEpsilon(CGAffineTransform t1, CGAffineTransform t2) {
    return ( compareFloatsEpsilon(t1.a, t2.a)
            && compareFloatsEpsilon(t1.b, t2.b)
            && compareFloatsEpsilon(t1.c, t2.c)
            && compareFloatsEpsilon(t1.d, t2.d)
            && compareFloatsEpsilon(t1.tx, t2.tx)
            && compareFloatsEpsilon(t1.ty, t2.ty)
            );
}

static inline BOOL CATransform3DEqualToTransformEpsilon(CATransform3D t1, CATransform3D t2) {
    return ( compareFloatsEpsilon(t1.m11, t2.m11)
            && compareFloatsEpsilon(t1.m12, t2.m12)
            && compareFloatsEpsilon(t1.m13, t2.m13)
            && compareFloatsEpsilon(t1.m14, t2.m14)
            && compareFloatsEpsilon(t1.m21, t2.m21)
            && compareFloatsEpsilon(t1.m22, t2.m22)
            && compareFloatsEpsilon(t1.m23, t2.m23)
            && compareFloatsEpsilon(t1.m24, t2.m24)
            && compareFloatsEpsilon(t1.m31, t2.m31)
            && compareFloatsEpsilon(t1.m32, t2.m32)
            && compareFloatsEpsilon(t1.m33, t2.m33)
            && compareFloatsEpsilon(t1.m34, t2.m34)
            && compareFloatsEpsilon(t1.m41, t2.m41)
            && compareFloatsEpsilon(t1.m42, t2.m42)
            && compareFloatsEpsilon(t1.m43, t2.m43)
            && compareFloatsEpsilon(t1.m44, t2.m44)
            );
}

- (void)testExport {
    ExportObjectInstanceCount = 0; @autoreleasepool {

    LuaContext *ctx = [LuaContext new];

    NSError *error = nil;

    NSString *script =
@"function publicFn () local v = ex.publicMethod() print(v) return v end"
" function publicPr () local v = ex.publicString print(v) return v end"
" function privateFn () local v = ex.privateMethod() print(v) return v end"
" function privatePr () local v = ex.privateString print(v) return v end"
" function floatProp (v) ex.floatProperty = v return v end"
" function setPublicPr (v) ex.publicString = v print(v) return v end";
    [ctx parse:script error:&error];
    XCTAssert( ! error, @"failed to load script: %@", error);

    id result;
    ExportObject *ex = [ExportObject new];
    ctx[@"ex"] = ex;

    result = [ctx call:"publicFn" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    ex.silence = YES;
    XCTAssert( [result isEqualToString:[ex publicMethod]], @"result is wrong");
    ex.silence = NO;

    result = [ctx call:"publicPr" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");

    result = [ctx call:"floatProp" with:@[ @M_PI ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( compareFloatsEpsilon([result floatValue], ex.floatProperty), @"result is wrong");

    result = [ctx call:"privateFn" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"private access succeeded");
    ex.silence = YES;
    XCTAssert( ! [result isEqualToString:[ex privateMethod]], @"result is wrong");
    ex.silence = NO;
    error = nil;

    result = [ctx call:"privatePr" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"private access succeeded");
    XCTAssert( ! [result isEqualToString:ex.privateString], @"result is wrong");
    error = nil;

    result = [ctx call:"setPublicPr" with:@[ @"new value" ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");

    result = [ctx call:"setPublicPr" with:@[ @"another value" ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");

    result = [ctx call:"publicPr" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");

    // This leads to a leak, see Issue #8
    result = [ctx call:"setPublicPr" with:@[ @5 ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"setting string to number succeeded");
    XCTAssert( ! [result isEqualToString:ex.publicString], @"result is wrong");
    error = nil;

    result = [ctx call:"setPublicPr" with:@[ [NSMutableString stringWithString:@"mutable test"] ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");

    } // triggers Issue #8: XCTAssert( ExportObjectInstanceCount == 0, "ExportObject leak (%s): %d", __func__, ExportObjectInstanceCount);
}

- (void)testComplexType {
    ExportObjectInstanceCount = 0; @autoreleasepool {
    
    LuaContext *ctx = [LuaContext new];

    NSError *error = nil;

    NSString *script =
@"function testVoid () ex.voidTakesStringAndNumber(\"string\", 6) end"
" function testRect1 () return ex.rectTakesArrayAndRect({1, 2, 3, 4}, { x = 4, y = 3, width = 2, height = 1 }) end"
" function testRect2 () return ex.rectTakesArrayAndRect(nil, { x = 5, y = 6, width = 7, height = 8 }) end"
" function testFloat () return ex.floatTakesNothing() end"
" function testXForm1 () return ex.transformTakesTransformAndFloat(CGAffineTransformIdentity, 1.5) end"
" function testXForm2 () return ex.transformTakesArrayAndFloat({1, 0, 0, 1, 0, 0}, 1.5) end"
" function test3DXFormPass (v) return ex.passThroughMatrix(v) end"
"";
    [ctx parse:script error:&error];
    XCTAssert( ! error, @"failed to load script: %@", error);

    id result;
    ExportObject *ex = [ExportObject new];
    ctx[@"ex"] = ex;
    ctx[@"CGAffineTransformIdentity"] = @[ @1.0, @0.0, @0.0, @1.0, @0.0, @0.0 ];

    result = [ctx call:"testVoid" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && ! error, @"failed with: %@", error);

    result = [ctx call:"testRect1" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( [result[@"x"] floatValue] == 1 && [result[@"y"] floatValue] == 2
              && [result[@"width"] floatValue] == 3 && [result[@"height"] floatValue] == 4 , @"wrong result");

    result = [ctx call:"testRect2" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( [result[@"x"] floatValue] == 5 && [result[@"y"] floatValue] == 6
              && [result[@"width"] floatValue] == 7 && [result[@"height"] floatValue] == 8 , @"wrong result");

    result = [ctx call:"testFloat" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( compareFloatsEpsilon([result floatValue], M_2_PI) && ! error, @"failed with: %@", error);

    result = [ctx call:"testXForm1" with:nil error:&error];
    CGAffineTransform expected = CGAffineTransformMakeRotation(1.5);
    NSLog(@"%d result: %@ expected: %@ error: %@", __LINE__, result, StringFromCGAffineTransform(expected), error);
    CGAffineTransform xform = CGAffineTransformFromArray(result);
    XCTAssert( CGAffineTransformEqualToTransformEpsilon(expected, xform) && ! error, @"failed with: %@", error);

    result = [ctx call:"testXForm2" with:nil error:&error];
    expected = CGAffineTransformMakeRotation(1.5);
    NSLog(@"%d result: %@ expected: %@ error: %@", __LINE__, result, StringFromCGAffineTransform(expected), error);
    xform = CGAffineTransformFromArray(result);
    XCTAssert( CGAffineTransformEqualToTransformEpsilon(expected, xform) && ! error, @"failed with: %@", error);

    result = [ctx call:"test3DXFormPass" with:@[ [NSValue valueWithBytes:&CATransform3DIdentity objCType:@encode(CATransform3D)] ] error:&error];
    NSLog(@"%d result: %@ expected: %@ error: %@", __LINE__, result, StringFromCATransform3D(CATransform3DIdentity), error);
    CATransform3D xform3d = CATransform3DFromArray(result);
    XCTAssert( CATransform3DEqualToTransformEpsilon(CATransform3DIdentity, xform3d) && ! error, @"failed with: %@", error);

    } XCTAssert( ExportObjectInstanceCount == 0, "ExportObject leak (%s): %d", __func__, ExportObjectInstanceCount);
}

- (void)testInheritance {
    ExportObjectInstanceCount = 0; @autoreleasepool {

    LuaContext *ctx = [LuaContext new];

    NSError *error = nil;

    NSString *script =
@"function publicFn () local v = ex.publicMethod() print(v) return v end"
" function publicFn2 () local v = ex.publicMethod2() print(v) return v end"
" function publicPr () local v = ex.publicString print(v) return v end"
" function publicPr2 () local v = ex.publicString2 print(v) return v end"
" function privateFn () local v = ex.privateMethod() print(v) return v end"
" function privateFn2 () local v = ex.privateMethod2() print(v) return v end"
" function privateFn3 () local v = ex.privateMethod3() print(v) return v end"
" function privatePr () local v = ex.privateString print(v) return v end"
" function privatePr2 () local v = ex.privateString2 print(v) return v end"
" function privatePr3 () local v = ex.privateString3 print(v) return v end"
" function setPublicPr (v) ex.publicString = v print(v) return v end"
" function setPublicPr2 (v) ex.publicString2 = v print(v) return v end";
    [ctx parse:script error:&error];
    XCTAssert( ! error, @"failed to load script: %@", error);

    id result;
    InheritedPrivateObject *ex = [InheritedPrivateObject new];
    ctx[@"ex"] = ex;

    result = [ctx call:"publicFn" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    ex.silence = YES;
    XCTAssert( [result isEqualToString:[ex publicMethod]], @"result is wrong");
    ex.silence = NO;

    result = [ctx call:"publicFn2" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    ex.silence = YES;
    XCTAssert( [result isEqualToString:[ex publicMethod2]], @"result is wrong");
    ex.silence = NO;

    result = [ctx call:"publicPr" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");

    result = [ctx call:"publicPr2" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString2], @"result is wrong");


    result = [ctx call:"privateFn" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"private access succeeded");
    ex.silence = YES;
    XCTAssert( ! [result isEqualToString:[ex privateMethod]], @"result is wrong");
    ex.silence = NO;
    error = nil;

    result = [ctx call:"privateFn2" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"private access succeeded");
    ex.silence = YES;
    XCTAssert( ! [result isEqualToString:[ex privateMethod2]], @"result is wrong");
    ex.silence = NO;
    error = nil;

    result = [ctx call:"privateFn3" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"private access succeeded");
    ex.silence = YES;
    XCTAssert( ! [result isEqualToString:[ex privateMethod3]], @"result is wrong");
    ex.silence = NO;
    error = nil;

    result = [ctx call:"privatePr" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"private access succeeded");
    XCTAssert( ! [result isEqualToString:ex.privateString], @"result is wrong");
    error = nil;

    result = [ctx call:"privatePr2" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"private access succeeded");
    XCTAssert( ! [result isEqualToString:ex.privateString2], @"result is wrong");
    error = nil;

    result = [ctx call:"privatePr3" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"private access succeeded");
    XCTAssert( ! [result isEqualToString:ex.privateString3], @"result is wrong");
    error = nil;

    result = [ctx call:"setPublicPr" with:@[ @"new value" ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");

    result = [ctx call:"setPublicPr" with:@[ @"another value" ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");

    result = [ctx call:"publicPr" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");

    // This leads to a leak, see Issue #8
    result = [ctx call:"setPublicPr" with:@[ @5 ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"setting string to number succeeded");
    XCTAssert( ! [result isEqualToString:ex.publicString], @"result is wrong");
    error = nil;

    result = [ctx call:"setPublicPr" with:@[ [NSMutableString stringWithString:@"mutable test"] ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString], @"result is wrong");


    result = [ctx call:"setPublicPr2" with:@[ @"new value 2" ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString2], @"result is wrong");

    result = [ctx call:"setPublicPr2" with:@[ @"another value 2" ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString2], @"result is wrong");

    result = [ctx call:"publicPr2" with:nil error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString2], @"result is wrong");

    // This leads to a leak, see Issue #8
    result = [ctx call:"setPublicPr2" with:@[ @6 ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"setting string to number succeeded");
    XCTAssert( ! [result isEqualToString:ex.publicString2], @"result is wrong");
    error = nil;

    result = [ctx call:"setPublicPr2" with:@[ [NSMutableString stringWithString:@"mutable test 2"] ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! error, @"failed with: %@", error);
    XCTAssert( [result isEqualToString:ex.publicString2], @"result is wrong");

    } // triggers Issue #8: XCTAssert( ExportObjectInstanceCount == 0, "ExportObject leak (%s): %d", __func__, ExportObjectInstanceCount);
}

- (void)testPrint {
    ExportObjectInstanceCount = 0; @autoreleasepool {

    LuaContext *ctx = [LuaContext new];

    NSError *error = nil;

    NSString *script =
@"function testPrint (v) s = dumpVar(v) print(s) return s end"
"";
    [ctx parse:script error:&error];
    XCTAssert( ! error, @"failed to load script: %@", error);

    id result;

    result = [ctx call:"testPrint" with:@[ @"foo" ] error:&error];
    NSLog(@"result: %@ error: %@", result, error);
    XCTAssert( ! error, @"unexpected error: %@", error);
    XCTAssert( [result isEqualToString:@"foo"], @"result is wrong");

    result = [ctx call:"testPrint" with:@[ @1 ] error:&error];
    NSLog(@"error: %@", error);
    XCTAssert( ! error, @"unexpected error: %@", error);
    XCTAssert( [result isEqualToString:@"1"], @"result is wrong");

    result = [ctx call:"testPrint" with:@[ @[ @1, @2, @3 ] ] error:&error];
    NSLog(@"error: %@", error);
    XCTAssert( ! error, @"unexpected error: %@", error);
    // yes, this is dependent on how [NSArray description] behaves, but it's "good enough"
    XCTAssert( [result isEqualToString:@"(\n    1,\n    2,\n    3\n)"], @"result is wrong");

    result = [ctx call:"testPrint" with:@[ @{ @"a": @1, @"b": @2, @"c": @3 } ] error:&error];
    NSLog(@"error: %@", error);
    XCTAssert( ! error, @"unexpected error: %@", error);
    // yes, this is dependent on how [NSDictionary description] behaves, but it's "good enough"
    XCTAssert( [result isEqualToString:@"{\n    a = 1;\n    b = 2;\n    c = 3;\n}"], @"result is wrong");

    } XCTAssert( ExportObjectInstanceCount == 0, "ExportObject leak (%s): %d", __func__, ExportObjectInstanceCount);
}

- (void)testBlocks {
    ExportObjectInstanceCount = 0; @autoreleasepool {

    LuaContext *ctx = [LuaContext new];

    ctx[@"v22"] = ^{
        return @(22);
    };
    ctx[@"v33"] = ^{
        return @(33);
    };

    NSString *script = @"return v22() + v33()";

    NSError *error = nil;
    [ctx parse:script error:&error];
    XCTAssert( ! error, @"failed to load script: %@", error);

    XCTAssert( [ctx.parseResult isEqual:@(55)], @"block invocation failed");

    } XCTAssert( ExportObjectInstanceCount == 0, "ExportObject leak (%s): %d", __func__, ExportObjectInstanceCount);
}


- (void)testLeakIssue8 {
    ExportObjectInstanceCount = 0; @autoreleasepool {

    LuaContext *ctx = [LuaContext new];

    NSError *error = nil;
    NSString *script = @"function setPublicPr (v) ex.publicString = v print(v) return v end";
    [ctx parse:script error:&error];
    XCTAssert( ! error, @"failed to load script: %@", error);

    id result;
    ExportObject *ex = [ExportObject new];
    ctx[@"ex"] = ex;

    // This leads to a leak, see Issue #8
    result = [ctx call:"setPublicPr" with:@[ @5 ] error:&error];
    NSLog(@"%d result: %@ error: %@", __LINE__, result, error);
    XCTAssert( ! result && error, @"setting string to number succeeded");
    XCTAssert( ! [result isEqualToString:ex.publicString], @"result is wrong");
    error = nil;

    } XCTAssert( ExportObjectInstanceCount == 0, "ExportObject leak (%s): %d", __func__, ExportObjectInstanceCount);
}

@end
