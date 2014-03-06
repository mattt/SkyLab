// ViewController.m
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

#import "ViewController.h"
#import "SkyLab.h"

@implementation ViewController

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Simple A/B Test
    [SkyLab abTestWithName:@"Title" A:^{
        self.titleLabel.text = NSLocalizedString(@"Hello, World!", nil);
    } B:^{
        self.titleLabel.text = NSLocalizedString(@"Greetings, Planet!", nil);
    }];
    
    // Split Test with Weighted Probabilities
    [SkyLab splitTestWithName:@"Subtitle" choices:@{
        @"Red" : @(0.15),
        @"Green" : @(0.10),
        @"Blue" : @(0.50),
        @"Purple" : @(0.25)
     } block:^(id choice) {
         self.subtitleLabel.text = NSLocalizedString(@"Please Enjoy This Colorful Message", nil);

         if ([choice isEqualToString:@"Red"]) {
             self.subtitleLabel.textColor = [UIColor redColor];
         } else if ([choice isEqualToString:@"Green"]) {
             self.subtitleLabel.textColor = [UIColor greenColor];
         } else if ([choice isEqualToString:@"Blue"]) {
             self.subtitleLabel.textColor = [UIColor blueColor];
         } else if ([choice isEqualToString:@"Purple"]) {
             self.subtitleLabel.textColor = [UIColor purpleColor];
         }
    }];
    
    // Multivariate Test
    [SkyLab multivariateTestWithName:@"Switches" variables:@{
        @"Left" : @(0.5),
        @"Center" : @(0.5),
        @"Right" : @(0.5)
     } block:^(NSSet *activeVariables) {
         self.leftSwitch.on = [activeVariables containsObject:@"Left"];
         self.centerSwitch.on = [activeVariables containsObject:@"Center"];
         self.rightSwitch.on = [activeVariables containsObject:@"Right"];
    }];
}

#pragma mark - IBAction

- (IBAction)resetTests:(id)sender {
    [SkyLab resetTestNamed:@"Title"];
    [SkyLab resetTestNamed:@"Subtitle"];
    [SkyLab resetTestNamed:@"Switches"];
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tests Reset", nil) message:NSLocalizedString(@"Segmentation will be re-run on next launch", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil] show];
}

@end
