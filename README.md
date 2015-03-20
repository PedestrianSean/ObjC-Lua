ObjC-Lua
========

A simple Objective-C &lt;-> Lua bridge modeled after iOS 7's JavaScriptCore.

A trivial use might look like this:
```objective-c
static NSString *const myScript =
LUA_STRING(
           globalVar = { 0.0, 1.0 }
           
           function myFunction(parameter)
               return parameter >= globalVar[1] and parameter <= globalVar[2]
           end
);

- (void)doLua {
    LuaContext *ctx = [LuaContext new];
    NSError *error = nil;
    if( ! [ctx parse:myScript error:&error] ) {
        NSLog(@"Error parsing lua script: %@", error);
        return;
    }

    NSLog(@"globalVar is: %@", ctx[@"globalVar"]); // should print "globalVar is: [ 0.0, 1.0 ]"

    id result = [ctx call:@"myFunction" args:@[ @0.5 ] error:&error];
    if( error ) {
        NSLog(@"Error calling myFunction: %@", error);
        return;
    }
    NSLog(@"myFunction returned: %@", result); // should print "myFunction returned: '1'"

    ctx[@"globalVar"] = @[ 0.2, 0.4 ];

    result = [ctx call:@"myFunction" args:@[ @0.5 ] error:&error];
    if( error ) {
        NSLog(@"Error calling myFunction: %@", error);
        return;
    }
    NSLog(@"myFunction returned: %@", result); // should print "myFunction returned: '0'"
}
```

A more complex use might be:
```objective-c
static NSString *const myScript =
LUA_STRING(
           function moveView(view)
               local center = view.center
               center.y = center.y + 5
               center.x = center.x + 5
               view.center = center
           end
);

@protcol UIViewLuaExports <LuaExport>

@property(nonatomic) CGFloat alpha;
@property(nonatomic) CGRect bounds;
@property(nonatomic) CGPoint center;
@property(nonatomic) CGRect frame;

- (void)removeFromSuperview;

@end

@interface UIView (UIViewLuaExports) <UIViewLuaExports>
@end
@implementation UIView (UIViewLuaExports)
@end

- (void)doLua:(UIView*)onView {
    LuaContext *ctx = [LuaContext new];
    NSError *error = nil;
    if( ! [ctx parse:myScript error:&error] ) {
        NSLog(@"Error parsing lua script: %@", error);
        return;
    }

    [ctx call:@"moveView" args:@[ onView ] error:&error];
    if( error ) {
        NSLog(@"Error calling myFunction: %@", error);
        return;
    }
}
```
