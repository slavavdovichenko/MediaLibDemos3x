//
//  ViewController.m
//  RTMPPhotoStreamer
//
//  Created by Slava Vdovichenko on 6/26/15.
//  Copyright (c) 2015 The Midnight Coders, Inc. All rights reserved.
//

#import <mach/mach_time.h>
#import "ViewController.h"
#import "DEBUG.h"
#import "BroadcastStreamClient.h"
#import "VideoPlayer.h"

#define TAKE_PHOTO_ON 0

static NSString *host = @"rtmp://10.0.1.62:1935/live";
static NSString *stream = @"teststream";
static int clickInterval = 200; // ms

@interface ViewController () <MPIMediaStreamEvent> {
    
    BroadcastStreamClient       *upstream;
    FramesPlayer                *_player;
    MPVideoResolution           _resolution;
    
    AVCaptureSession            *session;
    AVCaptureVideoDataOutput    *videoDataOutput;
    AVCaptureVideoPreviewLayer  *previewLayer;
    AVCaptureVideoOrientation   _orientation;
    dispatch_queue_t            videoDataOutputQueue;
    BOOL                        isPhotoPicking;
    
}
@end

@interface ViewController (CaptureProcessing) <AVCaptureVideoDataOutputSampleBufferDelegate>
-(void)setupAVCapture;
-(void)teardownAVCapture;
@end


@interface ViewController (ImageProcessing)
-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image;
-(CGImageRef)imageFromPixelBuffer:(CVPixelBufferRef)frameBuffer;
@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //[DebLog setIsActive:YES];
    
    _player = [[FramesPlayer alloc] initWithView:self.imageView];
    
#if !TAKE_PHOTO_ON
    [self setupAVCapture];
    self.btnTakePhoto.hidden = YES;
#endif
    
    [self connect];
}

-(IBAction)takePhoto:(id)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}


#pragma mark -
#pragma mark - Image Picker Controller delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    int64_t _timestamp = [self getTimestampMs];
    
    NSLog(@"imagePickerController: timestamp = %lld", _timestamp);
    
    UIImage *image = info[UIImagePickerControllerEditedImage];
    [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES]; // MAIN THREAD
    
    CVPixelBufferRef pixelBuffer = [self pixelBufferFromCGImage:[image CGImage]];
    [upstream sendFrame:pixelBuffer timestamp:_timestamp];
    CVPixelBufferRelease(pixelBuffer);

    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -
#pragma mark Private Methods

-(void)connect {
    
    NSLog(@"******************> connect\n");
    
    //_resolution = RESOLUTION_LOW;
    //_resolution = RESOLUTION_CIF;
    //_resolution = RESOLUTION_MEDIUM;
    _resolution = RESOLUTION_VGA;
    
    upstream = [[BroadcastStreamClient alloc] initOnlyVideo:host resolution:_resolution];
    //upstream = [[BroadcastStreamClient alloc] init:host resolution:_resolution];
#if TAKE_PHOTO_ON
    [upstream setVideoCustom:5 width:640 height:640];
#else
    [upstream setVideoMode:VIDEO_CUSTOM];
#endif
    upstream.delegate = self;
    
    upstream.videoCodecId = MP_VIDEO_CODEC_H264;
    //upstream.videoCodecId = MP_VIDEO_CODEC_FLV1;
    upstream.audioCodecId = MP_AUDIO_CODEC_NONE;

    //_orientation = AVCaptureVideoOrientationPortrait;
    //_orientation = AVCaptureVideoOrientationPortraitUpsideDown;
    _orientation = AVCaptureVideoOrientationLandscapeRight;
    //orientation = AVCaptureVideoOrientationLandscapeLeft;
    
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

-(int64_t)getTimestampMs {
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    return 1e-6*mach_absolute_time()*info.numer/info.denom;
}

-(void)sendFrame:(CMSampleBufferRef)sampleBuffer {
    
    // Get the frame timestamp
    CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    int64_t _timestamp = presentationTimeStamp.value/(presentationTimeStamp.timescale/1000);
    
    // Send the frame
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [upstream sendFrame:pixelBuffer timestamp:_timestamp];
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


@implementation ViewController (CaptureProcessing)

-(void)setupAVCapture {
    
    isPhotoPicking = NO;
    
    // Create the session
    session = [AVCaptureSession new];
    [session setSessionPreset:[self captureSessionPreset]];
    
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

    // Make a video data output
    videoDataOutput = [AVCaptureVideoDataOutput new];
    NSDictionary *rgbOutputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCMPixelFormat_32BGRA)};
    [videoDataOutput setVideoSettings:rgbOutputSettings];
    [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    // Create a serial queue to handle the processing of our frames
    videoDataOutputQueue = dispatch_queue_create("com.themidnightcoders.RTMPPhotoPublisher", DISPATCH_QUEUE_SERIAL);
    [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
    if ([session canAddOutput:videoDataOutput])
        [session addOutput:videoDataOutput];

    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    CALayer *rootLayer = [self.previewView layer];
    [rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:[rootLayer bounds]];
    [rootLayer addSublayer:previewLayer];
    
    [session commitConfiguration];
    
    //[self setOrientation:_orientation];
    
    [session startRunning];
    
    [self flushFrame];
}

// clean up capture setup
-(void)teardownAVCapture {
    
    if (upstream.state != CONN_CONNECTED)
        return;
    
    videoDataOutput = nil;
    
    [previewLayer removeFromSuperlayer];
    previewLayer = nil;
    
    session = nil;
}

-(void)setOrientation:(AVCaptureVideoOrientation)orientation {
    
    if (!videoDataOutput)
        return;
    
    for (AVCaptureConnection *connection in videoDataOutput.connections) {
        
        [DebLog logY:@"setVideoOrientation: isVideoOrientationSupported = %@, , orientation = %d -> %d", connection.isVideoOrientationSupported?@"YES":@"NO", connection.videoOrientation, orientation];
        
        if (connection.isVideoOrientationSupported) {
            [session beginConfiguration];
            connection.videoOrientation = orientation;
            [session commitConfiguration];
        }
    }
}

-(NSString *)captureSessionPreset {
    
    switch (_resolution) {
        case RESOLUTION_LOW:
            return AVCaptureSessionPresetLow;
        case RESOLUTION_CIF:
            return AVCaptureSessionPreset352x288;
        case RESOLUTION_MEDIUM:
            return AVCaptureSessionPresetMedium;
        case RESOLUTION_VGA:
            return AVCaptureSessionPreset640x480;
        case RESOLUTION_HIGH:
            return AVCaptureSessionPresetHigh;
        default:
            return AVCaptureSessionPresetLow;
    }
}

-(void)flushFrame {
    
    if (upstream && (upstream.state == STREAM_PLAYING)) {
        isPhotoPicking = YES;
    }
    
    dispatch_time_t interval = dispatch_time(DISPATCH_TIME_NOW, 1ull*NSEC_PER_MSEC*clickInterval);
    dispatch_after(interval, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self flushFrame];
    });
}


#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate Methods

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    if (!isPhotoPicking)
        return;
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [_player playImageBuffer:pixelBuffer];
#if 0
    [self sendFrame:sampleBuffer];
#else
    int64_t _timestamp = [self getTimestampMs];
    NSLog(@"captureOutput: timestamp = %lld", _timestamp);
    
    CGImageRef frame = [self imageFromPixelBuffer:pixelBuffer];
    CVPixelBufferRef framePixelBuffer = [self pixelBufferFromCGImage:frame];
    [upstream sendFrame:framePixelBuffer timestamp:_timestamp];
    
    CVPixelBufferRelease(framePixelBuffer);
    CGImageRelease(frame);
#endif
    
    isPhotoPicking = NO;
}

@end


@implementation ViewController (ImageProcessing)

// !!! after using need !!! - CVPixelBufferRelease(pixelBuffer);
-(CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image {
    
    // config the options
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t bitsPerComponent = 8; // *not* CGImageGetBitsPerComponent(image);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bi = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little; // *not* CGImageGetBitmapInfo(image);
    NSDictionary *options = @{(id)kCVPixelBufferCGImageCompatibilityKey:@YES, (id)kCVPixelBufferCGBitmapContextCompatibilityKey:@YES};
    
    // create pixel buffer
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pxbuffer);
    
    CGContextRef context = CGBitmapContextCreate(pxdata, width, height, bitsPerComponent, bytesPerRow, cs, bi);
    if (context == NULL){
        [DebLog logY:@"pixelBufferFromCGImage: (ERROR) could not create context"];
    }
    else {
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        CGContextRelease(context);
    }
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    CGColorSpaceRelease(cs);
    
    return pxbuffer;
}

// !!! after using need !!! - CGImageRelease(cgImage);
-(CGImageRef)imageFromPixelBuffer:(CVPixelBufferRef)frameBuffer {
    
    if (!frameBuffer)
        return nil;
    
    // Lock the image buffer
    CVPixelBufferLockBaseAddress(frameBuffer, 0);
    
    // Get the pixel buffer width and height.
    size_t width = CVPixelBufferGetWidth(frameBuffer);
    size_t height = CVPixelBufferGetHeight(frameBuffer);
    // Get the base address of the pixel buffer.
    uint8_t *frame = CVPixelBufferGetBaseAddress(frameBuffer);
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(frameBuffer);
    // Get the device color space
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    // Bitmap options
    CGBitmapInfo bi = kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little;
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, frame, bufferSize, NULL);
    // Create a bitmap image from data supplied by the data provider.
    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bufferSize/height, cs, bi, dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    // Unlock the  image buffer
    CVPixelBufferUnlockBaseAddress(frameBuffer, 0);
    
    return cgImage;
}

// !!! after using need !!! - CGImageRelease(cgImage);
-(CGImageRef)imageFromImageBuffer:(CVImageBufferRef)imageBuffer {
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *context = [CIContext contextWithOptions:nil];
    return [context createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer))];
}

@end

