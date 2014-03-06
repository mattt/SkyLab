// SkyLab.m
//
// Copyright (c) 2012 Mattt Thompson (http://mattt.me/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SkyLab.h"

#include <stdlib.h>

NSString * const SkyLabWillRunTestNotification = @"SkyLabWillRunTestNotification";
NSString * const SkyLabDidRunTestNotification = @"SkyLabDidRunTestNotification";
NSString * const SkyLabDidResetTestNotification = @"SkyLabDidResetTestNotification";

NSString * const SkyLabConditionKey = @"com.skylab.condition";
NSString * const SkyLabActiveVariablesKey = @"com.skylab.active-variables";
#define SkyLabChoiceKey SkyLabConditionKey

static NSString * SLUserDefaultsKeyForTestName(NSString *name) {
    static NSString * const kSLUserDefaultsKeyFormat = @"SkyLab-%@";

    return [NSString stringWithFormat:kSLUserDefaultsKeyFormat, name];
}

static id SLRandomValueFromArray(NSArray *array) {
    if ([array count] == 0) {
        return nil;
    }
    
    return [array objectAtIndex:(NSUInteger)arc4random_uniform([array count])];
}

static dispatch_once_t srand48OnceToken;

static id SLRandomKeyFromDictionaryWithWeightedValues(NSDictionary *dictionary) {
    if ([dictionary count] == 0) {
        return nil;
    }
    
    NSArray *keys = [dictionary allKeys];
    NSMutableArray *mutableWeightedSums = [NSMutableArray arrayWithCapacity:[keys count]];
    
    double total = 0.0;
    for (id key in keys) {
        total += [dictionary[key] doubleValue];
        [mutableWeightedSums addObject:@(total)];
    }
    
    dispatch_once(&srand48OnceToken, ^{
        srand48(time(0));
    });
    
    double r = drand48() * total;
    
    __block id randomObject = nil;
    [mutableWeightedSums enumerateObjectsUsingBlock:^(NSNumber *cumulativeWeightedSum, NSUInteger idx, BOOL *stop) {
        if (r <= [cumulativeWeightedSum doubleValue]) {
            randomObject = keys[idx];
            *stop = YES;
        }
    }];
    
    return randomObject;
}

static BOOL SLRandomBinaryChoiceWithProbability(double p) {
    dispatch_once(&srand48OnceToken, ^{
        srand48(time(0));
    });
    
    return drand48() <= p;
}

static BOOL SLRandomBinaryChoice() {
    return SLRandomBinaryChoiceWithProbability(0.5);
}

@implementation SkyLab

+ (void)abTestWithName:(NSString *)name
                     A:(void (^)())A
                     B:(void (^)())B
{
    [self splitTestWithName:name conditions:[NSArray arrayWithObjects:@"A", @"B", nil] block:^(NSString *choice) {
        if ([choice isEqualToString:@"A"] && A) {
            A();
        } else if ([choice isEqualToString:@"B"] && B) {
            B();
        }
    }];
}

+ (void)splitTestWithName:(NSString *)name
                  choices:(id)choices
                    block:(void (^)(id choice))block
{
    [self splitTestWithName:name conditions:(id <NSFastEnumeration>)choices block:block];
}

+ (void)splitTestWithName:(NSString *)name
               conditions:(id <NSFastEnumeration>)conditions
                    block:(void (^)(id))block;
{
    id condition = [[NSUserDefaults standardUserDefaults] objectForKey:SLUserDefaultsKeyForTestName(name)];

    if ([(id <NSObject>)conditions isKindOfClass:[NSDictionary class]]) {
        if (!condition || ![[(NSDictionary *)conditions allKeys] containsObject:condition]) {
            condition = SLRandomKeyFromDictionaryWithWeightedValues((NSDictionary *)conditions);
        }
    } else {
        BOOL containsCondition = NO;
        NSMutableArray *mutableCandidates = [NSMutableArray array];
        for (id candidate in conditions) {
            [mutableCandidates addObject:candidate];
            containsCondition = containsCondition || [condition isEqual:candidate];
        }

        if (!condition || !containsCondition) {
            condition = SLRandomValueFromArray(mutableCandidates);
        }
    }

    BOOL needsSynchronization = ![condition isEqual:[[NSUserDefaults standardUserDefaults] objectForKey:SLUserDefaultsKeyForTestName(name)]];
    [[NSUserDefaults standardUserDefaults] setObject:condition forKey:SLUserDefaultsKeyForTestName(name)];
    if (needsSynchronization) {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    if (block) {
        NSDictionary *userInfo = @{SkyLabConditionKey: condition};

        [[NSNotificationCenter defaultCenter] postNotificationName:SkyLabWillRunTestNotification object:name userInfo:userInfo];
        block(condition);
        [[NSNotificationCenter defaultCenter] postNotificationName:SkyLabDidRunTestNotification object:name userInfo:userInfo];
    }
}

+ (void)multivariateTestWithName:(NSString *)name
                       variables:(id <NSFastEnumeration>)variables
                           block:(void (^)(NSSet *assignedVariables))block
{
    NSSet *activeVariables = [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:SLUserDefaultsKeyForTestName(name)]];

    if ([(id <NSObject>)variables isKindOfClass:[NSDictionary class]]) {
        if (!activeVariables || ![activeVariables isKindOfClass:[NSSet class]] || ![activeVariables intersectsSet:[NSSet setWithArray:[(NSDictionary *)variables allKeys]]]) {
            NSMutableSet *mutableActiveVariables = [NSMutableSet setWithCapacity:[(NSDictionary *)variables count]];
            [(NSDictionary *)variables enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (SLRandomBinaryChoiceWithProbability([obj doubleValue])) {
                    [mutableActiveVariables addObject:key];
                }
            }];
            activeVariables = mutableActiveVariables;
        }
    } else {
        NSMutableSet *mutableActiveVariables = [NSMutableSet set];
        for (id variable in variables) {
            if ([activeVariables containsObject:variable] || SLRandomBinaryChoice()) {
                [mutableActiveVariables addObject:variable];
            }
        }

        activeVariables = mutableActiveVariables;
    }

    BOOL needsSynchronization = ![activeVariables isEqualToSet:[NSSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:SLUserDefaultsKeyForTestName(name)]]];
    [[NSUserDefaults standardUserDefaults] setObject:[activeVariables allObjects] forKey:SLUserDefaultsKeyForTestName(name)];
    if (needsSynchronization) {
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    if (block) {
        NSDictionary *userInfo = @{SkyLabActiveVariablesKey: activeVariables};

        [[NSNotificationCenter defaultCenter] postNotificationName:SkyLabWillRunTestNotification object:name userInfo:userInfo];
        block(activeVariables);
        [[NSNotificationCenter defaultCenter] postNotificationName:SkyLabDidRunTestNotification object:name userInfo:userInfo];
    }
}

+ (void)resetTestNamed:(NSString *)name {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SLUserDefaultsKeyForTestName(name)];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:SkyLabDidResetTestNotification object:name];
}

@end
