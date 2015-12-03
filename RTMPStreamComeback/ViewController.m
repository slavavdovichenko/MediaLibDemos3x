//
//  ViewController.m
//  RTMPStreamComeback
//
//  Created by Vyacheslav Vdovichenko on 11/13/12.
//  Copyright (c) 2014 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "DEBUG.h"
#import "MemoryTicker.h"
#import "BroadcastStreamClient.h"
#import "MPMediaDecoder.h"

#define IS_CROSS_STREAMS 0

// ON/OFF cross streams mode
#if IS_CROSS_STREAMS
static BOOL isCrossStreams = YES;   // Makes video chat (two separate streams) between iPhone and iPad devices
#else
static BOOL isCrossStreams = NO;    // Makes output & input streams on the one device
#endif

static NSString *host = @"rtmp://10.0.1.62:1935/live";
static NSString *stream = @"teststream";


@interface ViewController () <MPIMediaStreamEvent> {
    
    MemoryTicker            *memoryTicker;

    BroadcastStreamClient   *upstream;
    MPMediaDecoder          *decoder;
    
    MPVideoResolution       resolution;
    AVCaptureVideoOrientation orientation;
    
    int                     upstreamCross;
    int                     downstreamCross;

    UIActivityIndicatorView *netActivity;
}

-(void)sizeMemory:(NSNumber *)memory;
-(void)setDisconnect;
@end


@implementation ViewController

#pragma mark -
#pragma mark  View lifecycle

-(void)viewDidLoad {
    
    //[DebLog setIsActive:YES];
    
    [super viewDidLoad];
    
    memoryTicker = [[MemoryTicker alloc] initWithResponder:self andMethod:@selector(sizeMemory:)];
    memoryTicker.asNumber = YES;

    upstream = nil;
    decoder = nil;
    
    // isPad fixes kind of device: iPad (YES) or iPhone (NO)
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    
    // if isCrossStreams - makes 'teststream1' & 'teststream2' cross streams, else - one 'teststream0' stream for output & input
    upstreamCross = isCrossStreams?isPad?2:1:0;
    downstreamCross = isCrossStreams?isPad?1:2:0;

	// Create and add the activity indicator
	netActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:isPad?UIActivityIndicatorViewStyleGray:UIActivityIndicatorViewStyleWhiteLarge];
	netActivity.center = isPad? CGPointMake(400.0f, 480.0f) : CGPointMake(160.0f, 240.0f);
	[self.view addSubview:netActivity];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#if 0
-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
#endif
#pragma mark -
#pragma mark Private Methods

// MEMORY

-(void)sizeMemory:(NSNumber *)memory {
    memoryLabel.text = [NSString stringWithFormat:@"%d", [memory intValue]];
}

// ALERT

-(void)showAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Receive" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [av show];
    });
}

-(void)doConnect {
    
    resolution = RESOLUTION_LOW;
    //resolution = RESOLUTION_CIF;
    //resolution = RESOLUTION_MEDIUM;
    //resolution = RESOLUTION_VGA;
    
    upstream = [[BroadcastStreamClient alloc] init:host resolution:resolution];
    //upstream = [[BroadcastStreamClient alloc] initOnlyAudio:host];
    //upstream = [[BroadcastStreamClient alloc] initOnlyVideo:host resolution:resolution];
    
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

    NSString *name = [NSString stringWithFormat:@"%@%d", stream, upstreamCross];
    [upstream stream:name publishType:PUBLISH_LIVE];
    
    btnConnect.title = @"Disconnect";
    
    [netActivity startAnimating];
}

-(void)doPlay {
    
    decoder = [[MPMediaDecoder alloc] initWithView:streamView];
    decoder.delegate = self;
    decoder.isRealTime = YES;
    
    decoder.orientation = UIImageOrientationUp;
    
    NSString *name = [NSString stringWithFormat:@"%@/%@", host, [NSString stringWithFormat:@"%@%d", stream, downstreamCross]];
    [decoder setupStream:name];
    
    btnPublish.title = @"Pause";
    btnToggle.enabled = YES;
}

-(void)doDisconnect {
    [upstream disconnect];
}

-(void)setDisconnect {
    
    NSLog(@" ******************> setDisconnect");
    
    [decoder cleanupStream];
    decoder = nil;
    
    upstream = nil;
   
    btnConnect.title = @"Connect";
    btnToggle.enabled = NO;
    
    btnPublish.title = @"Start";
    btnPublish.enabled = NO;
    
    streamView.hidden = YES;
    previewView.hidden = YES;
    
    [netActivity stopAnimating];
}

#pragma mark -
#pragma mark Public Methods

// ACTIONS

-(IBAction)connectControl:(id)sender {
    
    NSLog(@"connectControl: host = %@", host);
    
    streamView.hidden? [self doConnect] : [self doDisconnect];
}

-(IBAction)publishControl:(id)sender {
    
    NSLog(@"publishControl: stream = %@", stream);
    
    if (isCrossStreams)
        [self doPlay];
    else
        (upstream.state != STREAM_PLAYING)? [upstream start] : [upstream pause];
}

-(IBAction)camerasToggle:(id)sender {
    
    NSLog(@"camerasToggle:");
    
    if (upstream.state != STREAM_PLAYING)
        return;
    
    [upstream switchCameras];
}

#pragma mark -
#pragma mark MPIMediaStreamEvent Methods

-(void)stateChanged:(id)sender state:(MPMediaStreamState)state description:(NSString *)description {
    
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> stateChangedEvent: sender = %@, %d = %@ [%@]", [sender class], (int)state, description, [NSThread isMainThread]?@"M":@"T");
    
    if (sender == upstream) {
        
        switch (state) {
                
            case CONN_DISCONNECTED: {
                
                [self setDisconnect];
                 
                break;
            }
                
            case CONN_CONNECTED: {
                
                if (![description isEqualToString:MP_RTMP_CLIENT_IS_CONNECTED])
                    break;
                
                [upstream start];
                
                btnPublish.enabled = YES;
                
                break;
            }
                
            case STREAM_PAUSED: {
                
                btnPublish.title = @"Start";
                btnToggle.enabled = NO;
                
                break;
            }
                
            case STREAM_PLAYING: {
                
                [upstream setPreviewLayer:previewView];
                previewView.hidden = NO;
                
                if (!isCrossStreams) {
                    [self performSelectorOnMainThread:@selector(doPlay) withObject:nil waitUntilDone:NO];
                }
                break;
            }
                
            default:
                break;
        }
    }
    
    if (sender == decoder) {
        
        switch (state) {
            
            case STREAM_PLAYING: {
                
                if ([description isEqualToString:MP_NETSTREAM_PLAY_STREAM_NOT_FOUND]) {
                    
                    [self connectControl:nil];
                    [self showAlert:description];
                    
                    break;
                }
                
                streamView.hidden = (decoder.videoCodecId == MP_VIDEO_CODEC_NONE);
                [netActivity stopAnimating];

                break;
            }
                
            default:
                break;
        }
    }
}

-(void)connectFailed:(id)sender code:(int)code description:(NSString *)description {
    
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> connectFailedEvent: %d = %@  [%@]", code, description, [NSThread isMainThread]?@"M":@"T");
    
    if (!upstream)
        return;
    
    [self setDisconnect];
    
    [self showAlert:(code == -1)?
     @"Unable to connect to the server. Make sure the hostname/IP address and port number are valid" :
     [NSString stringWithFormat:@"connectFailedEvent: %@", description]];
}

-(void)metadataReceived:(id)sender event:(NSString *)event metadata:(NSDictionary *)metadata {
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> dataReceived: EVENT: %@, METADATA = %@  [%@]", event, metadata, [NSThread isMainThread]?@"M":@"T");
}

@end
