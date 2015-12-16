//
//  ViewController.m
//  RTMPStreamPlayer
//
//  Created by Vyacheslav Vdovichenko on 7/11/12.
//  Copyright (c) 2014 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import "DEBUG.h"
#import "MemoryTicker.h"
#import "MediaStreamPlayer.h"
#import "VideoPlayer.h"
#import "MPMediaDecoder.h"


@interface ViewController () <MPIMediaStreamEvent> {
    
    MemoryTicker            *memoryTicker;
    MPMediaDecoder          *decoder;
    BOOL                    isLive;
    
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
    
    [self initNetActivity];
    
    memoryTicker = [[MemoryTicker alloc] initWithResponder:self andMethod:@selector(sizeMemory:)];
    memoryTicker.asNumber = YES;
    
    decoder = nil;
    
#if 1
    //hostTextField.text = @"rtmp://localhost:1935/live";
    //hostTextField.text = @"rtmp://[fe80::6233:4bff:fe1a:8488]:1935/live"; // ipv6
    hostTextField.text = @"rtmp://10.0.1.62:1935/live";
    hostTextField.delegate = self;
    
    streamTextField.text = @"teststream";
	streamTextField.delegate = self;
    
    isLive = YES;
#else
    
    //hostTextField.text = @"rtmp://localhost:1935/vod";
    hostTextField.text = @"rtmp://10.0.1.62:1935/vod";
    hostTextField.delegate = self;
    
    streamTextField.text = @"sample";
    streamTextField.delegate = self;
    
    isLive = NO;
#endif
}

-(void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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
        [[[UIAlertView alloc] initWithTitle:@"Receive" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    });
}

-(void)initNetActivity {
    
    // isPad fixes kind of device: iPad (YES) or iPhone (NO)
    BOOL isPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
    // Create and add the activity indicator
    netActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:isPad?UIActivityIndicatorViewStyleGray:UIActivityIndicatorViewStyleWhiteLarge];
    netActivity.center = isPad? CGPointMake(400.0f, 480.0f) : CGPointMake(160.0f, 240.0f);
    [self.view addSubview:netActivity];
}

-(void)doConnect {
    
    decoder = [[MPMediaDecoder alloc] initWithView:previewView];
    decoder.delegate = self;
    decoder.isRealTime = isLive;
    
    decoder.orientation = UIImageOrientationUp;
    
    [decoder setupStream:[NSString stringWithFormat:@"%@/%@", hostTextField.text, streamTextField.text]];

    btnConnect.title = @"Disconnect";
    
    [netActivity startAnimating];
}

-(void)setDisconnect {
    
    [decoder cleanupStream];
    decoder = nil;
    
    btnConnect.title = @"Connect";
    btnPlay.title = @"Start";
    btnPlay.enabled = NO;
    
    hostTextField.hidden = NO;
    streamTextField.hidden = NO;
    
    previewView.hidden = YES;
    
    [netActivity stopAnimating];
}

#pragma mark -
#pragma mark Public Methods 

// ACTIONS

-(IBAction)connectControl:(id)sender {
    
    NSLog(@"******************************************** connectControl: host = %@", hostTextField.text);
    
    (!decoder) ? [self doConnect] : [self setDisconnect];
}

-(IBAction)playControl:(id)sender; {
    
    NSLog(@"********************************************* playControl: stream = %@", streamTextField.text);
    
    (decoder.state != STREAM_PLAYING) ? [decoder resume] : [decoder pause];
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark -
#pragma mark MPIMediaStreamEvent Methods

-(void)stateChanged:(id)sender state:(MPMediaStreamState)state description:(NSString *)description {
    
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> stateChangedEvent: %d = %@ [%@]", (int)state, description, [NSThread isMainThread]?@"M":@"T");
    
    switch (state) {
            
        case STREAM_CREATED: {
            
            hostTextField.hidden = YES;
            streamTextField.hidden = YES;
            
            btnPlay.enabled = YES;
            
            break;
            
        }
            
        case STREAM_PAUSED: {
            
            if ([description isEqualToString:MP_NETSTREAM_PLAY_STREAM_NOT_FOUND]) {
                
                [self connectControl:nil];
                [self showAlert:description];
                
                break;
            }
            
            btnPlay.title = @"Start";
            
            break;
        }
        
        case STREAM_PLAYING: {
            
            if ([description isEqualToString:MP_RESOURCE_TEMPORARILY_UNAVAILABLE]) {
                [self showAlert:description];
                break;
            }
            
            if ([description isEqualToString:MP_NETSTREAM_PLAY_STREAM_NOT_FOUND]) {
                
                [self connectControl:nil];
                [self showAlert:description];
                
                break;
            }
            
            //[MPMediaData routeAudioToSpeaker];
            
            [netActivity stopAnimating];
            previewView.hidden = (decoder.videoCodecId == MP_VIDEO_CODEC_NONE);
            
            btnPlay.title = @"Pause";
            
            break;
        }
            
        default:
            break;
    }
}

-(void)connectFailed:(id)sender code:(int)code description:(NSString *)description {
    
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> connectFailedEvent: %d = %@ [%@]", code, description, [NSThread isMainThread]?@"M":@"T");
    
    if (!decoder)
        return;
    
    [self setDisconnect];
    
    [self showAlert:(code == -1) ?
     @"Unable to connect to the server. Make sure the hostname/IP address and port number are valid" :
     [NSString stringWithFormat:@"connectFailedEvent: %@", description]];
}

-(void)metadataReceived:(id)sender event:(NSString *)event metadata:(NSDictionary *)metadata {
    NSLog(@" $$$$$$ <MPIMediaStreamEvent> dataReceived: EVENT: %@, METADATA = %@ [%@]", event, metadata, [NSThread isMainThread]?@"M":@"T");
}

@end
