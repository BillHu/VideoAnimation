//
//  VAAnimationLayer.h
//  VideoAnimation
//
//  Created by BillHu on 13-8-17.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface VAAnimationLayer : CALayer{
    
    unsigned int sampleIndex;
}

@property (nonatomic)unsigned int previousIndex;

@property (readwrite, nonatomic) unsigned int sampleIndex;

@property (nonatomic)BOOL printCurrentSampleIndex;

- (unsigned int)currentSampleIndex;

@end
