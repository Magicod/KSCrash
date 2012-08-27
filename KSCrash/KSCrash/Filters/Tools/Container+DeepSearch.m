//
//  Container+DeepSearch
//  KSCrash
//
//  Created by Karl Stenerud on 12-08-25.
//
//

#import "Container+DeepSearch.h"

#pragma mark - Base functionality

static BOOL isNumericString(NSString* str)
{
    if([str length] == 0)
    {
        return YES;
    }
    unichar ch = [str characterAtIndex:0];
    return ch >= '0' && ch <= '9';
}

static id objectForDeepKey(id container, NSArray* deepKey)
{
    for(id key in deepKey)
    {
        if([container respondsToSelector:@selector(objectForKey:)])
        {
            container = [(NSDictionary*)container objectForKey:key];
        }
        else
        {
            if([container respondsToSelector:@selector(objectAtIndex:)] &&
               [key respondsToSelector:@selector(intValue)])
            {
                if([key isKindOfClass:[NSString class]] && !isNumericString(key))
                {
                    return nil;
                }
                NSUInteger index = (NSUInteger)[key intValue];
                container = [container objectAtIndex:index];
            }
            else
            {
                return nil;
            }
        }
        if(container == nil)
        {
            break;
        }
    }
    return container;
}

static id objectForKeyPath(id container, NSString* keyPath)
{
    return objectForDeepKey(container, [keyPath componentsSeparatedByString:@"/"]);
}

static id parentOfDeepKey(id container, NSArray* deepKey)
{
    NSUInteger deepKeyCount = [deepKey count];
    switch(deepKeyCount)
    {
        case 0:
        {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"deepKey must contain at least one key"
                                         userInfo:nil];
            break;
        }
        case 1:
        {
            return container;
        }
        default:
        {
            NSArray* parentKey = [deepKey subarrayWithRange:NSMakeRange(0, deepKeyCount - 1)];
            id parent = objectForDeepKey(container, parentKey);
            if(parent == nil)
            {
                NSString* reason = [NSString stringWithFormat:
                                    @"Parent %@ does not resolve to a valid object",
                                    parentKey];
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:reason
                                             userInfo:nil];
            }
            return parent;
        }
    }
}

static void setObjectForDeepKey(id container, id object, NSArray* deepKey)
{
    NSString* excFormat = nil;
    id lastKey = [deepKey objectAtIndex:[deepKey count] - 1];
    id parentContainer = parentOfDeepKey(container, deepKey);
    if([parentContainer respondsToSelector:@selector(setObject:forKey:)])
    {
        [(NSMutableDictionary*)parentContainer setObject:object forKey:lastKey];
        return;
    }
    else if([lastKey respondsToSelector:@selector(intValue)])
    {
        if([parentContainer respondsToSelector:@selector(replaceObjectAtIndex:withObject:)])
        {
            NSUInteger index = (NSUInteger)[lastKey intValue];
            [(NSMutableArray*)parentContainer replaceObjectAtIndex:index withObject:object];
            return;
        }
        else
        {
            excFormat = @"Parent %@ of type %@ does not respond to \"setObject:forKey:\" or \"replaceObjectAtIndex:withObject:\"";
        }
    }
    else
    {
        excFormat = @"Parent %@ of type %@ does not respond to \"setObject:forKey:\"";
    }

    NSArray* parentKey = [deepKey subarrayWithRange:NSMakeRange(0, [deepKey count] - 1)];
    NSString* reason = [NSString stringWithFormat:excFormat, parentKey, [parentContainer class]];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:reason
                                 userInfo:nil];
}

static void setObjectForKeyPath(id container, id object, NSString* keyPath)
{
    setObjectForDeepKey(container, object, [keyPath componentsSeparatedByString:@"/"]);
}

static void removeObjectForDeepKey(id container, NSArray* deepKey)
{
    NSString* excFormat = nil;
    id lastKey = [deepKey objectAtIndex:[deepKey count] - 1];
    id parentContainer = parentOfDeepKey(container, deepKey);
    if([parentContainer respondsToSelector:@selector(removeObjectForKey:)])
    {
        [(NSMutableDictionary*)parentContainer removeObjectForKey:lastKey];
        return;
    }
    else if([lastKey respondsToSelector:@selector(intValue)])
    {
        if([parentContainer respondsToSelector:@selector(removeObjectAtIndex:)])
        {
            NSUInteger index = (NSUInteger)[lastKey intValue];
            [(NSMutableArray*)parentContainer removeObjectAtIndex:index];
            return;
        }
        else
        {
            excFormat = @"Parent %@ of type %@ does not respond to \"removeObjectForKey:\" or \"removeObjectAtIndex:\"";
        }
    }
    else
    {
        excFormat = @"Parent %@ of type %@ does not respond to \"removeObjectForKey:\"";
    }

    NSArray* parentKey = [deepKey subarrayWithRange:NSMakeRange(0, [deepKey count] - 1)];
    NSString* reason = [NSString stringWithFormat:excFormat, parentKey, [parentContainer class]];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:reason
                                 userInfo:nil];
}

static void removeObjectForKeyPath(id container, NSString* keyPath)
{
    removeObjectForDeepKey(container, [keyPath componentsSeparatedByString:@"/"]);
}


#pragma mark - NSDictionary Category

@implementation NSDictionary (DeepSearch)

- (id) objectForDeepKey:(NSArray*) deepKey
{
    return objectForDeepKey(self, deepKey);
}

- (id) objectForKeyPath:(NSString*) keyPath
{
    return objectForKeyPath(self, keyPath);
}

- (void) setObject:(id) anObject forDeepKey:(NSArray*) deepKey
{
    setObjectForDeepKey(self, anObject, deepKey);
}

- (void) setObject:(id) anObject forKeyPath:(NSString*) keyPath
{
    setObjectForKeyPath(self, anObject, keyPath);
}

- (void) removeObjectForDeepKey:(NSArray*) deepKey
{
    removeObjectForDeepKey(self, deepKey);
}

- (void) removeObjectForKeyPath:(NSString*) keyPath
{
    removeObjectForKeyPath(self, keyPath);
}

@end


#pragma mark - NSArray Category

@implementation NSArray (DeepSearch)

- (id) objectForDeepKey:(NSArray*) deepKey
{
    return objectForDeepKey(self, deepKey);
}

- (id) objectForKeyPath:(NSString*) keyPath
{
    return objectForKeyPath(self, keyPath);
}

- (void) setObject:(id) anObject forDeepKey:(NSArray*) deepKey
{
    setObjectForDeepKey(self, anObject, deepKey);
}

- (void) setObject:(id) anObject forKeyPath:(NSString*) keyPath
{
    setObjectForKeyPath(self, anObject, keyPath);
}

- (void) removeObjectForDeepKey:(NSArray*) deepKey
{
    removeObjectForDeepKey(self, deepKey);
}

- (void) removeObjectForKeyPath:(NSString*) keyPath
{
    removeObjectForKeyPath(self, keyPath);
}

@end
