//
//  VAAnimationLayer.m
//  VideoAnimation
//
//  Created by BillHu on 13-8-17.
//
//

#import "VAAnimationLayer.h"

@implementation VAAnimationLayer

@synthesize sampleIndex;

- (id)init
{
    self = [super init];
    if (self) {
        sampleIndex = 0;
    }
    return self;
}


+ (BOOL)needsDisplayForKey:(NSString *)key
{
    return [key isEqualToString:@"sampleIndex"];
}


// contentsRect or bounds changes are not animated
//+ (id < CAAction >)defaultActionForKey:(NSString *)aKey;
//{
////    MGLOG(@"defaultActionForKey:%@",aKey);
//    if ([aKey isEqualToString:@"contents"])
//        return (id < CAAction >)[NSNull null];
//
//    return [super defaultActionForKey:aKey];
//}


- (unsigned int)currentSampleIndex
{
    return ((VAAnimationLayer*)[self presentationLayer]).sampleIndex;
}

- (void)display
{
    
    unsigned int currentSampleIndex = [self currentSampleIndex];
    
    if(currentSampleIndex == self.previousIndex){
        return;
    }
    if(self.printCurrentSampleIndex){
        NSLog(@"currentSampleIndex:%d",currentSampleIndex);
    }
    self.previousIndex = currentSampleIndex;
    
    self.contents = (__bridge id)([UIImage imageNamed:[NSString stringWithFormat:@"BouncingBalls%d.png",currentSampleIndex]].CGImage);
}

@end
