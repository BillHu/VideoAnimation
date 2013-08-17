//
//  VAViewController.m
//  VideoAnimation
//
//  Created by BillHu on 13-8-17.
//
//

#import "VAViewController.h"
#import "VAAnimationLayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface VAViewController ()

@property (nonatomic)CGSize videoSize;

@property (nonatomic,strong)AVAssetExportSession* exporter;

@property (nonatomic,strong)NSTimer* exportProgressTimer;

@property(nonatomic,strong)MPMoviePlayerController *player;

@end

@implementation VAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    VAAnimationLayer* animationLayer = [VAAnimationLayer layer];
    animationLayer.frame = self.animationView.bounds;
    [self.animationView.layer addSublayer: animationLayer];
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"sampleIndex"];
    anim.beginTime = AVCoreAnimationBeginTimeAtZero;
    anim.fromValue = [NSNumber numberWithInt:1];
    anim.toValue = [NSNumber numberWithInt:31];
    anim.duration = 3.0;
    anim.removedOnCompletion = NO;
    anim.repeatCount = HUGE_VALF;
    
    [animationLayer addAnimation:anim forKey:nil];
    
}


- (IBAction)exportAnimationToVideo:(id)sender {
    if(self.exporter.status == AVAssetExportSessionStatusExporting){
        return;
    }
    
    [self.videoView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self deleteMOVFilesAt:NSTemporaryDirectory()];
    
    self.videoSize = CGSizeMake(640 , 480);
    
    
    // animation tool
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    
    parentLayer.bounds = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
    parentLayer.anchorPoint =  CGPointMake(0, 0);
    parentLayer.position = CGPointMake(0, 0);
    
    
    videoLayer.bounds = CGRectMake(0, 0, self.videoSize.width, self.videoSize.height);
    videoLayer.anchorPoint =  CGPointMake(0.5, 0.5);
    videoLayer.position = CGPointMake(CGRectGetMidX(parentLayer.bounds), CGRectGetMidY(parentLayer.bounds));
    [parentLayer addSublayer:videoLayer];
    
    parentLayer.geometryFlipped = YES;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    parentLayer.sublayerTransform = CATransform3DMakeScale(screenScale, screenScale, 1);
    
    
    // animation
    VAAnimationLayer* videoAnimationLayer = [VAAnimationLayer layer];
    videoAnimationLayer.frame = self.animationView.bounds;
    videoAnimationLayer.printCurrentSampleIndex = YES;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"sampleIndex"];
    anim.beginTime = AVCoreAnimationBeginTimeAtZero;
    anim.fromValue = [NSNumber numberWithInt:1];
    anim.toValue = [NSNumber numberWithInt:31];
    anim.duration = 3.0;
    anim.removedOnCompletion = NO;
    anim.repeatCount = HUGE_VALF;
    
    [videoAnimationLayer addAnimation:anim forKey:nil];
    [parentLayer addSublayer:videoAnimationLayer ];
    
    
    AVVideoCompositionCoreAnimationTool* animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    
    // insert a black video, so can add animation tool
    AVAsset *videoAsset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"blackback640x480" withExtension:@"mp4"]];
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    // Video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(1, 10000))
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    CMTime endTime = CMTimeMake(mixComposition.duration.value-1, 10000);
    // extend 30 seconds
    CMTime extendTime = CMTimeMake(30, 1);
    CMTimeRange emptyTimeRange = CMTimeRangeMake(endTime, extendTime);
    [mixComposition insertEmptyTimeRange:emptyTimeRange];
    
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration);
    mainInstruction.enablePostProcessing = YES;
    //
    //
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    mainCompositionInst.renderSize = self.videoSize;
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    
    // assign animationTool
    mainCompositionInst.animationTool = animationTool;
    
    
    NSString* tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempvideo.mov"];
    NSURL* tempVideoFileURL = [NSURL fileURLWithPath:tempVideoPath];
    
    _exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                 presetName:AVAssetExportPreset640x480];
    
    self.exporter.outputURL = tempVideoFileURL;
    self.exporter.outputFileType = AVFileTypeQuickTimeMovie;
    self.exporter.shouldOptimizeForNetworkUse = YES;
    self.exporter.videoComposition = mainCompositionInst;
    
    NSTimeInterval seconds = 0.1;
    _exportProgressTimer = [NSTimer scheduledTimerWithTimeInterval:seconds
                                                            target:self
                                                          selector:@selector(updateProgress)
                                                          userInfo:nil
                                                           repeats:YES];
    
    [self.exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self exportSegVideoDidFinish];
        });
    }];
    
}

- (void)exportSegVideoDidFinish{
    NSLog(@"status:%d",self.exporter.status);
    self.exporter = nil;
    
    
    NSString* tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempvideo.mov"];
    NSURL* tempVideoFileURL = [NSURL fileURLWithPath:tempVideoPath];
    
    _player =[[MPMoviePlayerController alloc] initWithContentURL:tempVideoFileURL];
    self.player.controlStyle=MPMovieControlStyleDefault;
    [self.player prepareToPlay];
    [self.player.view setFrame:self.videoView.bounds];
    [self.videoView addSubview: self.player.view];
    self.player.shouldAutoplay=YES;
}

- (void)updateProgress{
    AVAssetExportSessionStatus status = self.exporter.status;
    
    NSString* progress = [NSString stringWithFormat:@"%.2f%%",self.exporter.progress*100];
//    NSLog(@"progress:%@",progress);
    self.progressLabel.text = progress;
    
    if(!self.exporter || status == AVAssetExportSessionStatusCancelled ||
       status == AVAssetExportSessionStatusCompleted ||
       status == AVAssetExportSessionStatusFailed){
        
        self.progressLabel.text = nil;
        [self.exportProgressTimer invalidate];
		self.exportProgressTimer = nil;
    }
    
}


- (void)deleteMOVFilesAt:(NSString*)directory{
    NSError *err = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:directory];
    NSString *toDelVideoFile;
    while (toDelVideoFile = [dirEnum nextObject]) {
        if ([[toDelVideoFile pathExtension] isEqualToString: @"mov"]) {
            NSLog(@"removing file：%@",toDelVideoFile);
            if(![fileManager removeItemAtPath:[directory stringByAppendingPathComponent:toDelVideoFile] error:&err]){
                NSLog(@"Error: %@", [err localizedDescription]);
            }
        }
    }
}










- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setAnimationView:nil];
    [self setVideoView:nil];
    [self setProgressLabel:nil];
    [super viewDidUnload];
}
@end
