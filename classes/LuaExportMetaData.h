//
//  LuaExportUserData.h
//  Givit
//
//  Created by Sean Meiners on 2013/11/19.
//
//

#import <Foundation/Foundation.h>

@interface LuaExportMetaData : NSObject

// Note: To prevent leaks (see issue #8), we must declare all instance references with the `__unsafe_unretained`
// keyword so that ARC won't insert retain+release calls, as they would break if we leave the subroutine prematurely
// with a `jongjmp()` thru `lua_error(L)` due to an error state.
// And it's important to also add the same keyword in the @implementation (".m" file), or it won't work!

- (instancetype)init;

- (void)addAllowedProperty:(const char*)propertyName withAttrs:(const char*)attrs;

- (BOOL)canReadProperty:(const char*)propertyName;
- (BOOL)canWriteProperty:(const char*)propertyName;

- (id)getProperty:(const char*)propertyName onInstance:(id __unsafe_unretained)instance;
- (void)setProperty:(const char*)propertyName toValue:(id)value onInstance:(id __unsafe_unretained)instance;

- (void)addAllowedMethod:(const char*)methodName withTypes:(const char*)types;

- (BOOL)canCallMethod:(const char*)methodName;

- (id)callMethod:(const char*)method withArgs:(NSArray*)args onInstance:(id __unsafe_unretained)instance;

@end
