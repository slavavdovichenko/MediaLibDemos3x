//
//  ViewController.m
//  RTMPStreamComeback
//
//  Created by Vyacheslav Vdovichenko on 11/13/12.
//  Copyright (c) 2012 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "DEBUG.h"
#import "MemoryTicker.h"
#import "BroadcastStreamClient.h"
#import "MediaStreamPlayer.h"
#import "VideoPlayer.h"
#import "MPMediaEncoder.h"
#import "MPMediaDecoder.h"


//static NSString *host = @"rtmp://10.0.1.33:1935/live";
//static NSString *host = @"rtmp://192.168.2.63:1935/live";
//static NSString *host = @"rtmp://192.168.2.101:1935/live";
static NSString *host = @"rtmp://192.168.1.102:1935/live";
//static NSString *host = @"rtmp://192.168.2.101:1935/live";
//static NSString *host = @"rtmp://80.74.155.7/live";

//static NSString *stream = @"outgoingaudio_c11";
//static NSString *stream = @"myStream";
static NSString *stream = @"slavav";

// cross stream mode
static BOOL isCrossStreams = NO;
//static BOOL isCrossStreams = YES;


@interface ViewController () <MPIMediaStreamEvent> {
    
    MemoryTicker            *memoryTicker;
    FramesPlayer            *screen;
    
    RTMPClient              *socket;
    BroadcastStreamClient   *upstream;
    MediaStreamPlayer       *player;
    
    MPMediaDecoder          *decoder;
    
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

    socket = nil;
    upstream = nil;
    player = nil;
    
    decoder = nil;
    
    //echoCancellationOff;
    
    upstreamCross = isCrossStreams ? ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 2 : 1) : 0;
    downstreamCross = isCrossStreams ? ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? 1 : 2) : 0;
	
	// Create and add the activity indicator
	netActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	netActivity.center = CGPointMake(160.0f, 200.0f);
	[self.view addSubview:netActivity];
    
    // setup the simultaneous record and playback
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -
#pragma mark Private Methods

// MEMORY

-(void)sizeMemory:(NSNumber *)memory {
    memoryLabel.text = [NSString stringWithFormat:@"%d", [memory intValue]];
}

// ALERT

-(void)showAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Receive" message:message delegate:self
                                           cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [av show];
    });
}

-(void)doConnect {
    
    NSString *name = [NSString stringWithFormat:@"%@%d", stream, upstreamCross];
    
    MPVideoResolution resolution = RESOLUTION_LOW;
    
#if 1 // use inside RTMPClient instance
    
    upstream = [[BroadcastStreamClient alloc] init:host resolution:resolution];
    //upstream = [[BroadcastStreamClient alloc] initOnlyAudio:host];
    //upstream = [[BroadcastStreamClient alloc] initOnlyVideo:host resolution:resolution];
    
#else // use outside RTMPClient instance
    
    if (!socket) {
        socket = [[RTMPClient alloc] init:host];
        if (!socket) {
            [self showAlert:@"Socket has not be created"];
            return;
        }
        
        [socket spawnSocketThread];
    }
    
    upstream = [[BroadcastStreamClient alloc] initWithClient:socket resolution:RESOLUTION_LOW];
    //upstream = [[BroadcastStreamClient alloc] initOnlyAudioWithClient:socket];
    //upstream = [[BroadcastStreamClient alloc] initOnlyVideoWithClient:socket resolution:RESOLUTION_LOW];
    //[upstream setVideoBitrate:32000];
    
#endif
    
    upstream.delegate = self;
    [upstream stream:name publishType:PUBLISH_LIVE];
    
    //[netActivity startAnimating];
    
    btnConnect.title = @"Disconnect";
    streamView.hidden = NO;

}

-(void)doPlay {
    
#if 1 // ------------------ use MPMediaDecoder
    
    decoder = [[MPMediaDecoder alloc] initWithView:streamView];
    [decoder setupStream:[NSString stringWithFormat:@"%@/%@", host, [NSString stringWithFormat:@"%@%d", stream, upstreamCross]]];
    
#else
    
    // --------------------- use RTMPClient
    
    NSString *name = [NSString stringWithFormat:@"%@%d", stream, downstreamCross];
    
    screen = [[FramesPlayer alloc] initWithView:streamView];
    screen.orientation = UIImageOrientationRight;
    
    player = [[MediaStreamPlayer alloc] initWithClient:socket];
    player.delegate = self;
    player.player = screen;
    [player stream:name];
    
#endif
    
    btnPublish.title = @"Pause";
    btnToggle.enabled = YES;
}

-(void)doDisconnect {
    [player disconnect];
    [upstream disconnect];
}

-(void)setDisconnect {
    
    NSLog(@" ******************> setDisconnect");
    
    [decoder cleanupStream];
    decoder = nil;
    
    [socket disconnect];
    socket = nil;
    screen = nil;
    player = nil;
    upstream = nil;
    
    [netActivity stopAnimating];
   
    btnConnect.title = @"Connect";
    btnToggle.enabled = NO;
    
    btnPublish.title = @"Start";
    btnPublish.enabled = NO;
    
    streamView.hidden = YES;
}

-(void)sendMetadata {
    
    NSString *camera = upstream.isUsingFrontFacingCamera ? @"FRONT" : @"BACK";
    NSDate *date = [NSDate date];
    NSDictionary *meta = [NSDictionary dictionaryWithObjectsAndKeys:camera, @"camera", [date description], @"date", nil];
    [upstream sendMetadata:meta event:@"changedCamera:"];
}

#pragma mark -
#pragma mark Public Methods

// ACTIONS

-(IBAction)connectControl:(id)sender {
    
    NSLog(@"connectControl: host = %@", host);
    
    (streamView.hidden) ? [self doConnect] : [self doDisconnect];
}

-(IBAction)publishControl:(id)sender {
    
    NSLog(@"publishControl: stream = %@", stream);
    
    if (isCrossStreams)
        player ? ((player.state != STREAM_PLAYING ? [player start] : [player pause])) : [self doPlay];
    else
        (upstream.state != STREAM_PLAYING) ? [upstream start] : [upstream pause];
}

-(IBAction)camerasToggle:(id)sender {
    
    NSLog(@"camerasToggle:");
    
    if (upstream.state != STREAM_PLAYING)
        return;
    
    [upstream switchCameras];
    
    [self sendMetadata];
}

#pragma mark -
#pragma mark MPIMediaStreamEvent Methods

-(void)stateChanged:(id)sender state:(MPMediaStreamState)state description:(NSString *)description {
    
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> stateChangedEvent: sender = %@, %d = %@", [sender class], (int)state, description);
    
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
                
                if (player)
                    [player pause];
                
                btnPublish.title = @"Start";
                btnToggle.enabled = NO;
                
                break;
            }
                
            case STREAM_PLAYING: {
                
                [self sendMetadata];
               
                if (!isCrossStreams)
                    [self doPlay];
                
                break;
            }
                
            default:
                break;
        }
    }
    
    if (sender == player) {
        
        switch (state) {
                
            case STREAM_CREATED: {
                
                [netActivity stopAnimating];
                
                [player start];
                
                streamView.hidden = NO;
                
                break;
            }
                
            default:
                break;
        }
    }
}

-(void)connectFailed:(id)sender code:(int)code description:(NSString *)description {
    
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> connectFailedEvent: %d = %@\n", code, description);
    
    if (!upstream)
        return;
    
    [self setDisconnect];
    
    [self showAlert:(code == -1) ?
     @"Unable to connect to the server. Make sure the hostname/IP address and port number are valid" :
     [NSString stringWithFormat:@"connectFailedEvent: %@", description]];
}

-(void)metadataReceived:(id)sender event:(NSString *)event metadata:(NSDictionary *)metadata {
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> dataReceived: EVENT: %@, METADATA = %@", event, metadata);
}

/*/// Send metadata for each video frame
 -(void)pixelBufferShouldBePublished:(CVPixelBufferRef)pixelBuffer timestamp:(int)timestamp {
     
     //[upstream sendMetadata:@{@"videoTimestamp":[NSNumber numberWithInt:timestamp]} event:@"videoFrameOptions:"];
     
     //
     CVPixelBufferRef frameBuffer = pixelBuffer;
     
     // Get the base address of the pixel buffer.
     uint8_t *baseAddress = CVPixelBufferGetBaseAddress(frameBuffer);
     // Get the data size for contiguous planes of the pixel buffer.
     size_t bufferSize = CVPixelBufferGetDataSize(frameBuffer);
     // Get the pixel buffer width and height.
     size_t width = CVPixelBufferGetWidth(frameBuffer);
     size_t height = CVPixelBufferGetHeight(frameBuffer);
     
     [upstream sendMetadata:@{@"videoTimestamp":[NSNumber numberWithInt:timestamp], @"bufferSize":[NSNumber numberWithInt:bufferSize], @"width":[NSNumber numberWithInt:width], @"height":[NSNumber numberWithInt:height]} event:@"videoFrameOptions:"];
     //
 }
/*/

@end
