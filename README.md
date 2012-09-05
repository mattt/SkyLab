# SkyLab
**Multivariate & A/B Testing for iOS and Mac**

SkyLab is a backend-agnostic framework for [multivariate](http://en.wikipedia.org/wiki/Multivariate_testing) and [A/B testing](http://en.wikipedia.org/wiki/A/B_testing).

Test conditions are persisted across sessions and launches using `NSUserDefaults`, ensuring that every user will have a consistent experience, no matter which testing bucket they end up in.

SkyLab integrates easily into any existing statistics web service. Depending on your particular needs, this may include posting to an endpoint in test blocks, or perhaps setting an HTTP header for a shared API client. 

**Requests for integration with any particular backend are heartily encouraged.**

## Usage

Check ouf the included example project to see everything in action.

### Simple A/B Test

```objective-c
[SkyLab abTestWithName:@"Title" A:^{
    self.titleLabel.text = NSLocalizedString(@"Hello, World!", nil);
} B:^{
    self.titleLabel.text = NSLocalizedString(@"Greetings, Planet!", nil);
}];
```

### Split Test with Weighted Probabilities

You can pass either an `NSDictionary` (with values representing the weighted probability of their corresponding key) or an `NSArray` (with each value having an equal chance of being chosen) into the `choices` parameter.

```objective-c
[SkyLab splitTestWithName:@"Subtitle" choices:@{
    @"Red" : @(0.15),
    @"Green" : @(0.10),
    @"Blue" : @(0.50),
    @"Purple" : @(0.25)
 } block:^(id choice) {
     self.subtitleLabel.text = NSLocalizedString(@"Please Enjoy This Colored Message", nil);

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
```

### Multivariate Test

```objective-c
[SkyLab multivariateTestWithName:@"Switches" variables:@{
    @"Left" : @(0.5),
    @"Center" : @(0.5),
    @"Right" : @(0.5)
 } block:^(NSSet *activeVariables) {
     self.leftSwitch.on = [activeVariables containsObject:@"Left"];
     self.centerSwitch.on = [activeVariables containsObject:@"Center"];
     self.rightSwitch.on = [activeVariables containsObject:@"Right"];
}];
```

## Creators

[Mattt Thompson](http://github.com/mattt)  
[@mattt](https://twitter.com/mattt)

## License

SkyLab is available under the MIT license. See the LICENSE file for more info.

