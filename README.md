ObjC-Lua
========

A simple Objective-C &lt;-> Lua bridge modeled after iOS 7's and macOS' JavaScriptCore.

A trivial use might look like this:

```objective-c
static NSString *const myScript =
LUA_STRING(
  globalVar = { 0.0, 1.0 }
  
  function myFunction(parameter)
    return parameter >= globalVar[1] and parameter <= globalVar[2]
  end
  
  return doubleThisValue(2) * 3
);

- (void)doLua {
    LuaContext *ctx = [LuaContext new];
    
    // install the global function `doubleThisValue` as a block
    ctx[@"doubleThisValue"] = ^(NSNumber *v) {
        // we receive and return NSNumber objects, not plain ints!
        return @(v.integerValue * 2);
    };
    
    NSError *error = nil;
    if( ! [ctx parse:myScript error:&error] ) {
        NSLog(@"Error parsing lua script: %@", error);
        return;
    }
    
    NSLog(@"the script returned: %@ (should be 12)", ctx.parseResult);

    NSLog(@"globalVar is: %@ (should be “(0,1)”)", ctx[@"globalVar"]);

    id result = [ctx call:"myFunction" with:@[ @0.5 ] error:&error];
    if( error ) {
        NSLog(@"Error calling myFunction: %@", error);
        return;
    }
    NSLog(@"myFunction returned: %@ (should be 1)", result);

    ctx[@"globalVar"] = @[ @0.2, @0.4 ];
    NSLog(@"globalVar is: %@ (should be “(0.2,0.4)”)", ctx[@"globalVar"]);

    result = [ctx call:"myFunction" with:@[ @0.5 ] error:&error];
    if( error ) {
        NSLog(@"Error calling myFunction: %@", error);
        return;
    }
    NSLog(@"myFunction returned: %@ (should be 0)", result);
}
```

Here's a more complex use that involves an entire
class exposed to Lua (via the `LuaExport` protocol,
similar to [JSExport](https://developer.apple.com/documentation/javascriptcore/jsexport)).

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

@protocol UIViewLuaExports <LuaExport>

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

    [ctx call:"moveView" with:@[ onView ] error:&error];
    if( error ) {
        NSLog(@"Error calling myFunction: %@", error);
        return;
    }
}
```
