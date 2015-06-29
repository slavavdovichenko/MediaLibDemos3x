//
//  ViewController.m
//  RTMPPhotoStreamer
//
//  Created by Slava Vdovichenko on 6/26/15.
//  Copyright (c) 2015 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import "DEBUG.h"
#import "BroadcastStreamClient.h"
#import "MPMediaDecoder.h"

static NSString *host = @"rtmp://10.0.1.62:1935/live";
static NSString *stream = @"photostream";
static int clickInterval = 2; // sec

@interface ViewController () <MPIMediaStreamEvent> {
    
    BroadcastStreamClient   *upstream;
    
    AVCaptureSession            *session;
    AVCaptureVideoDataOutput    *videoDataOutput;
    AVCaptureVideoPreviewLayer  *previewLayer;
    dispatch_queue_t            videoDataOutputQueue;
    AVCaptureStillImageOutput   *stillImageOutput;
    UIView                      *flashView;
    BOOL                        isPhotoPicking;
    int                         count;
}
@end


@interface ViewController (MediaProcessing) <AVCaptureVideoDataOutputSampleBufferDelegate>
-(void)setupAVCapture;
-(void)teardownAVCapture;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[DebLog setIsActive:YES];
    
    [self connect];
}

#pragma mark -
#pragma mark Private Methods

-(void)connect {
    
    NSLog(@"******************> connect\n");
    
    upstream = [[BroadcastStreamClient alloc] initOnlyVideo:host resolution:RESOLUTION_LOW];
    [upstream setVideoMode:VIDEO_CUSTOM];
    upstream.delegate = self;
    
    upstream.videoCodecId = MP_VIDEO_CODEC_H264;
    upstream.audioCodecId = MP_AUDIO_CODEC_NONE;
    [upstream setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    [upstream stream:stream publishType:PUBLISH_LIVE];
}

-(void)disconnect {
    
    NSLog(@"******************> disconnect\n");
    
    [self teardownAVCapture];
    [upstream disconnect];
}

-(void)getDisconnected {
    
    NSLog(@"******************> getDisconnected\n");
    
    upstream = nil;
}

-(void)start {
    
    NSLog(@"******************> start\n");
    
    [upstream start];
}

-(void)sendFrame:(CMSampleBufferRef)sampleBuffer {
    
    // Get the frame timestamp
    CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    int64_t timestamp = presentationTimeStamp.value/(presentationTimeStamp.timescale/1000);
    
    // Send the frame
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [upstream sendFrame:pixelBuffer timestamp:timestamp];
}



#pragma mark-
#pragma mark IMediaStreamEvent Methods

-(void)stateChanged:(id)sender state:(MPMediaStreamState)state description:(NSString *)description {
    
    NSLog(@" $$$$$$ <IMediaStreamEvent> stateChangedEvent: %d = %@", (int)state, description);
    
    switch (state) {
            
        case CONN_DISCONNECTED:
        {
            [self getDisconnected];
            break;
        }
            
        case CONN_CONNECTED:
        {
            if (![description isEqualToString:MP_RTMP_CLIENT_IS_CONNECTED])
                break;
            
            [self start];
            break;
        }
            
        case STREAM_PAUSED:
        {
            if ([description isEqualToString:MP_NETSTREAM_PLAY_STREAM_NOT_FOUND]) {
                [self disconnect];
                return;
            }
            
            break;
        }
            
        case STREAM_PLAYING:
        {
            if (![description isEqualToString:MP_NETSTREAM_PUBLISH_START]) {
                [self disconnect];
                return;
            }
            
            [self setupAVCapture];
            break;
        }
            
        default:
            break;
    }
}

-(void)connectFailed:(id)sender code:(int)code description:(NSString *)description {
    
    NSLog(@" $$$$$$ <IMediaStreamEvent> connectFailedEvent: %d = %@\n", code, description);
    
    if (code > 0) {
        [self getDisconnected];
    }
}

@end

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";


@implementation ViewController (MediaProcessing)

-(void)setupAVCapture {
    
    isPhotoPicking = NO;
    
    // Create the session
    session = [AVCaptureSession new];
    // We use low quality
    [session setSessionPreset:AVCaptureSessionPresetLow];
    
    // Select a video device, make an input
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@" setupAVCapture - > ERROR: %@", [error localizedDescription]);
        session = nil;
        return;
    }
    
    if ([session canAddInput:deviceInput])
        [session addInput:deviceInput];
    
    // Make a still image output
    stillImageOutput = [AVCaptureStillImageOutput new];
    [stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)];
    if ( [session canAddOutput:stillImageOutput] )
        [session addOutput:stillImageOutput];
    
    // Make a video data output
    videoDataOutput = [AVCaptureVideoDataOutput new];
    NSDictionary *rgbOutputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCMPixelFormat_32BGRA]};
    [videoDataOutput setVideoSettings:rgbOutputSettings];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    // we create a serial queue to handle the processing of our frames
    videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    if ([session canAddOutput:videoDataOutput])
        [session addOutput:videoDataOutput];
    
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    CALayer *rootLayer = [previewView layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:previewLayer];
    [session commitConfiguration];
    
    [session startRunning];
    
    [self flushPhoto];
}

// clean up capture setup
-(void)teardownAVCapture {
    
    if (upstream.state != CONN_CONNECTED)
        return;
    
    videoDataOutput = nil;

    [stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage"];
    stillImageOutput = nil;
    
    [previewLayer removeFromSuperlayer];
    previewLayer = nil;
    
    session = nil;
}


// main action method to take an image
-(void)takePicture {
    
    isPhotoPicking = YES;
    
    // Find out the current orientation and tell the still image output.
    AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
     completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
         if (error) {
             NSLog(@"-> takePicture: error = %ld %@@>", (long)error.code, error.localizedDescription);
         }
     }];
}

-(void)flushPhoto {
    
    if (count++) [self takePicture];
    
    dispatch_time_t interval = dispatch_time(DISPATCH_TIME_NOW, 1ull*NSEC_PER_SEC*clickInterval);
    dispatch_after(interval, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self flushPhoto];
    });
}


#pragma mark -
#pragma mark KVO observation of the @"capturingStillImage" property

// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ( context == (__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext) ) {
        BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        if ( isCapturingStillImage ) {
            // do flash bulb like animation
            flashView = [[UIView alloc] initWithFrame:[previewView frame]];
            [flashView setBackgroundColor:[UIColor whiteColor]];
            [flashView setAlpha:0.f];
            [[[self view] window] addSubview:flashView];
            
            [UIView animateWithDuration:.4f
                             animations:^{
                                 [flashView setAlpha:1.f];
                             }
             ];
        }
        else {
            [UIView animateWithDuration:.4f
                             animations:^{
                                 [flashView setAlpha:0.f];
                             }
                             completion:^(BOOL finished){
                                 [flashView removeFromSuperview];
                                 flashView = nil;
                             }
             ];
        }
    }
}


#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate Methods

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (isPhotoPicking && upstream && (captureOutput == videoDataOutput)) {
        [self sendFrame:sampleBuffer];
    }
    
    isPhotoPicking = NO;
}

@end

