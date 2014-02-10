//
//  LuaContext.h
//  Givit
//
//  Created by Sean Meiners on 2013/11/19.
//
//

#import <Foundation/Foundation.h>

#define STRINGIZE_LUA(...) #__VA_ARGS__
#define STRINGIZE2_LUA(...) STRINGIZE_LUA(__VA_ARGS__)
#define LUA_STRING(...) @ STRINGIZE2_LUA(__VA_ARGS__)

extern NSString *const LuaErrorDomain;

typedef enum LuaErrorCode : NSUInteger {
    LuaError_Ok = 0,
    LuaError_Yield,
    LuaError_Runtime,
    LuaError_Syntax,
    LuaError_Memory,
    LuaError_GarbageCollector,
    LuaError_MessageHandler,
    LuaError_Invalid
} LuaErrorCode;

@interface LuaContext : NSObject

- (BOOL)parse:(NSString*)script error:(NSError**)error;
- (BOOL)parseURL:(NSURL*)url error:(NSError**)error;
- (id)call:(char*)name with:(NSArray*)args error:(NSError**)error;

- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(NSObject <NSCopying> *)key;

@end
