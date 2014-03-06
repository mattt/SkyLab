// SkyLab.h
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

#import <Foundation/Foundation.h>

/**
 SkyLab is a backend-agnostic framework for multivariate and A/B testing.
 
 The first time a test is run, the user will be randomly assigned to one of the specified conditions. These assignments are persisted across sessions and launches using `NSUserDefaults`, ensuring that each user will have a consistent experience.
 */
@interface SkyLab : NSObject

/**
 Run an A/B test in which the user is randomly assigned to execute `A` or `B`.
 
 @param name A unique identifier for the test.
 @param A A block to be executed for users assigned to the A condition. The block has no return value and takes no arguments.
 @param B A block to be executed for users assigned to the B condition. The block has no return value and takes no arguments.
 */
+ (void)abTestWithName:(NSString *)name
                     A:(void (^)())A
                     B:(void (^)())B;

/**
 Run a split test in which the user is randomly assigned to one of the specified conditions.

 @param name A unique identifier for the test.
 @param conditions The possible conditions for the user to be assigned. If this parameter is an `NSDictionary`, a weighted probability can be set as an `NSNumber` value for each condition. Otherwise, each condition will have the same probability of being assigned.
 @param block A block to be executed when the test is run. The block has no return value and takes a single argument: the assigned condition.
 */
+ (void)splitTestWithName:(NSString *)name
               conditions:(id <NSFastEnumeration>)conditions
                    block:(void (^)(id condition))block;

/**
 @warning This method has been deprecated in favor of `splitTestWithName:conditions:block:`
 */
+ (void)splitTestWithName:(NSString *)name
                  choices:(id)choices
                    block:(void (^)(id choice))block DEPRECATED_ATTRIBUTE;

/**
 Run a multivariate test in which the user is randomly assigned to a combination of specified variables.
 
 @param name A unique identifier for the test.
 @param variables The possible variables for the user to be assigned. If this parameter is an `NSDictionary`, a weighted probability can be set as an `NSNumber` value for each variable. Otherwise, each variable will have an even chance (`p = 0.5`) of being assigned.
 @param block A block to be executed when the test is run. The block has no return value and takes a single argument: the variables assigned to the user.
 */
+ (void)multivariateTestWithName:(NSString *)name
                       variables:(id <NSFastEnumeration>)variables
                           block:(void (^)(NSSet *assignedVariables))block;

/**
 Reset a particular test, by clearing any previous assignments for the user.
 
 @param name A unique identifier for the test.
 */
+ (void)resetTestNamed:(NSString *)name;

@end

///--------------------
/// @name Notifications
///--------------------

/**
 `SkyLabWillRunTestNotification`
 Posted before a SkyLab test is run. The object is the test name, and `userInfo` contains either the condition at `SkyLabConditionKey` for a split test or active variables at `SkyLabActiveVariablesKey` for a multivariate test.

 `SkyLabDidRunTestNotification`
 Posted after a SkyLab test is run. The object is the test name, and `userInfo` contains either the condition at `SkyLabConditionKey` for a split test or active variables at `SkyLabActiveVariablesKey` for a multivariate test.
 
 `SkyLabDidResetTestNotification`
 Posted when a test is reset. The object is the test name.
 */
extern NSString * const SkyLabWillRunTestNotification;
extern NSString * const SkyLabDidRunTestNotification;
extern NSString * const SkyLabDidResetTestNotification;

///----------------
/// @name Constants
///----------------

/**
 `SkyLabConditionKey`
 The `userInfo` key associated with the assigned condition for `SkyLabWillRunTestNotification` or `SkyLabDidRunTestNotification` notifications posted by a split test.
 
 `SkyLabConditionKey`
 The `userInfo` key associated with the active variables for `SkyLabWillRunTestNotification` or `SkyLabDidRunTestNotification` notifications posted by a multivariate test.
 */
extern NSString * const SkyLabChoiceKey DEPRECATED_ATTRIBUTE;
extern NSString * const SkyLabConditionKey;
extern NSString * const SkyLabActiveVariablesKey;
