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
static NSString *stream = @"teststream";

@interface ViewController () <UITextFieldDelegate, MPIMediaStreamEvent> {
    
    BroadcastStreamClient   *upstream;
    
    AVCaptureSession            *session;
    AVCaptureVideoDataOutput    *videoDataOutput;
    AVCaptureVideoPreviewLayer  *previewLayer;
    dispatch_queue_t            videoDataOutputQueue;
    AVCaptureStillImageOutput   *stillImageOutput;
    UIView                      *flashView;
    BOOL                        isUsingFrontFacingCamera;
    BOOL                        isPhotoPicking;
}
@end


@interface ViewController (MediaProcessing) <AVCaptureVideoDataOutputSampleBufferDelegate>
-(void)setupAVCapture;
-(void)teardownAVCapture;
-(UIImageOrientation)imageOrientation;
-(void)playImageData:(NSData *)data;
-(void)switchCameras;
-(void)takePicture;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [DebLog setIsActive:YES];
    
    upstream = nil;
    
    textField.text = stream;
    textField.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

-(BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    return YES;
}

#pragma mark -
#pragma mark IBAction Methods

-(IBAction)publish:(id)sender {
    [self connect];
}

-(IBAction)stop:(id)sender {
    [self disconnect];
}

-(IBAction)toggle:(id)sender {
    [self switchCameras];
}

-(IBAction)photo:(id)sender {
    [self takePicture];
}

#pragma mark -
#pragma mark Private Methods

-(void)connect {
    
    NSLog(@"connect\n");
    
    if (upstream)
        return;
    
    MPVideoResolution       resolution;
    AVCaptureVideoOrientation orientation;
    
    resolution = RESOLUTION_LOW;
    //resolution = RESOLUTION_CIF;
    //resolution = RESOLUTION_MEDIUM;
    //resolution = RESOLUTION_VGA;
    
    upstream = [[BroadcastStreamClient alloc] initOnlyVideo:host resolution:resolution];
    //[upstream setVideoMode:VIDEO_CUSTOM];
    upstream.delegate = self;
    
    
    //upstream.videoCodecId = MP_VIDEO_CODEC_FLV1;
    upstream.videoCodecId = MP_VIDEO_CODEC_H264;
    
    //upstream.audioCodecId = MP_AUDIO_CODEC_NELLYMOSER;
    upstream.audioCodecId = MP_AUDIO_CODEC_AAC;
    //upstream.audioCodecId = MP_AUDIO_CODEC_SPEEX;
    
    //[upstream setVideoBitrate:72000];
    
    orientation = AVCaptureVideoOrientationPortrait;
    //orientation = AVCaptureVideoOrientationPortraitUpsideDown;
    //orientation = AVCaptureVideoOrientationLandscapeRight;
    //orientation = AVCaptureVideoOrientationLandscapeLeft;
    [upstream setVideoOrientation:orientation];
    
    [upstream stream:textField.text publishType:switchLive.on?PUBLISH_LIVE:PUBLISH_RECORD];
    
    [netActivity startAnimating];
}

-(void)disconnect {
    
    NSLog(@"disconnect\n");
    
    [self teardownAVCapture];
    
    [upstream disconnect];
    
    [netActivity startAnimating];
}

-(void)getDisconnected {
    
    NSLog(@" ******************> getDisconnected");
    
    upstream = nil;
    
    previewView.hidden = YES;
    btnPublish.hidden = NO;
    btnStop.hidden = YES;
    btnToggle.hidden = YES;
    btnPhoto.hidden = YES;
    textField.enabled = YES;
    switchLive.enabled = YES;
    
    [netActivity stopAnimating];
}

-(void)start {
    
    NSLog(@"start\n");
    
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
            
            previewView.hidden = NO;
            btnPublish.hidden = YES;
            btnStop.hidden = NO;
            btnToggle.hidden = NO;
            btnPhoto.hidden = NO;
            textField.enabled = NO;
            switchLive.enabled = NO;
            
            [netActivity stopAnimating];
            
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


#define PRESET_LOW_BYTEPERROW 768
#define PRESET_LOW_HEIGHT 144
#define PRESET_LOW_WIDTH 192
#define PRESET_LOW_SCALE 1.0f

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";


@implementation ViewController (MediaProcessing)

-(void)setupAVCapture {
    
    isUsingFrontFacingCamera = YES;
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
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
    NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                       [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [videoDataOutput setVideoSettings:rgbOutputSettings];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
    videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    // we create a serial queue to handle the processing of our frames
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
    [self switchCameras];
    [session startRunning];
}

// clean up capture setup
-(void)teardownAVCapture {
    
    if (upstream.state != CONN_CONNECTED)
        return;
    
    [DebLog logN:@">>>>>>>>>> teardownAVCapture <<<<<<<<<<<<<<<<"];
    
    videoDataOutput = nil;
#if 0
    if (videoDataOutputQueue) {
        dispatch_release(videoDataOutputQueue);
    }
#endif
    [stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage"];
    stillImageOutput = nil;
    
    [previewLayer removeFromSuperlayer];
    previewLayer = nil;
    
    session = nil;
}

#if 1

-(UIImageOrientation)imageOrientation {
    return (isUsingFrontFacingCamera) ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
}

-(void)publishPixelBuffer:(CVPixelBufferRef)_frameBuffer {
    
    if (!isPhotoPicking)
        return;
    
    isPhotoPicking = NO;
    
    // Lock the image buffer
    CVPixelBufferLockBaseAddress(_frameBuffer, 0);
    
    // Get the base address of the pixel buffer.
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(_frameBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(_frameBuffer);
    // Get the number of bytes per row for the pixel buffer.
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(_frameBuffer);
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(_frameBuffer);
    size_t height = CVPixelBufferGetHeight(_frameBuffer);
    
    [DebLog log:@"-> publishPixelBuffer: size = %ld, width = %ld, height = %ld, bytesPerRow = %ld, thread = %@", bufferSize, width, height, bytesPerRow, [NSThread isMainThread]?@"MAIN":@"NOT MAIN"];
    
    // Send the frame to the server
    NSData *data = [NSData dataWithBytes:baseAddress length:bufferSize];
    [DebLog logN:@"\n-----------------------------\n%@\n-----------------------------\n", data];
    [self performSelectorOnMainThread:@selector(playImageData:) withObject:data waitUntilDone:NO]; // MAIN THREAD
    
    // Unlock the  image buffer
    CVPixelBufferUnlockBaseAddress(_frameBuffer, 0);
}

-(void)objectRelease:(id)obj {
    //[obj release];
}

-(void)playImageData:(NSData *)data {
    
    if (!data)
        return;
    
    UIImageOrientation orientation = [self imageOrientation];
    
    // Create a device-dependent RGB color space.
    static CGColorSpaceRef colorSpace = NULL;
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace == NULL) {
            [DebLog log:@"-> playImageData: (ERROR) Can't create a device-dependent RGB color space"];
            return;
        }
    }
    
    [DebLog logN:@"-> playImageData: size = %d, orientation = %u", data.length, orientation];
    [DebLog logN:@"\n-----------------------------\n%@\n-----------------------------\n", data];
    
    //[data retain];
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, (void *)data.bytes, data.length, NULL);
    // Create a bitmap image from data supplied by the data provider.
    CGImageRef cgImage = CGImageCreate(PRESET_LOW_WIDTH, PRESET_LOW_HEIGHT, 8, 32, PRESET_LOW_BYTEPERROW, colorSpace,
                                       kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little,
                                       dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    // Create an image object to represent the Quartz image.
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:PRESET_LOW_SCALE orientation:orientation];
    CGImageRelease(cgImage);
    
    [DebLog log:@"-> playImageData: image -> width = %g, height = %g, scale = %g, orientation = %u, thread = %@", image.size.width, image.size.height, image.scale, image.imageOrientation, [NSThread isMainThread]?@"MAIN":@"NOT MAIN"];
    
    //[self showPhoto:image];
    [self performSelector:@selector(objectRelease:) withObject:data afterDelay:0.2f];
}
#endif

// use front/back camera
-(void)switchCameras {
    
    AVCaptureDevicePosition desiredPosition = (isUsingFrontFacingCamera) ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([device position] == desiredPosition) {
            [session beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
            for (AVCaptureInput *oldInput in [session inputs]) {
                [session removeInput:oldInput];
            }
            [session addInput:input];
            [session commitConfiguration];
            break;
        }
    }
    
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

// main action method to take an image
-(void)takePicture {
    
    isPhotoPicking = YES;
    
    // Find out the current orientation and tell the still image output.
    AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [stillImageOutput
     captureStillImageAsynchronouslyFromConnection:stillImageConnection
     completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
         if (error) {
             NSLog(@"-> takePicture: error = %ld %@@>", (long)error.code, error.localizedDescription);
         }
     }];
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
                                 //[flashView release];
                                 flashView = nil;
                             }
             ];
        }
    }
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate Methods 

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {	
    
    if (upstream && (captureOutput == videoDataOutput)) {
        
        [DebLog logY:@">>>>>>>>>> captureOutput: <<<<<<<<<<<<<<<<"];
        [self publishPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
        [self sendFrame:sampleBuffer];
    }
}

@end

