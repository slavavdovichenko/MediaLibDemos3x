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
}

-(void)sizeMemory:(NSNumber *)memory;
-(void)setDisconnect;
@end


@implementation ViewController

#pragma mark -
#pragma mark  View lifecycle

-(void)viewDidLoad {
    
    [DebLog setIsActive:YES];
    
    [super viewDidLoad];
    
    memoryTicker = [[MemoryTicker alloc] initWithResponder:self andMethod:@selector(sizeMemory:)];
    memoryTicker.asNumber = YES;
    
    decoder = nil;

    hostTextField.text = @"rtmp://10.0.1.62:1935/live";
    hostTextField.delegate = self;
    
    streamTextField.text = @"teststream";
	streamTextField.delegate = self;
    
}

-(void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
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
#if 1
    [[[UIAlertView alloc] initWithTitle:@"Receive" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
#else
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [[[UIAlertView alloc] initWithTitle:@"Receive" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    });
#endif
}

-(void)doConnect {
    
    decoder = [[MPMediaDecoder alloc] initWithView:previewView];
    decoder.delegate = self;
    decoder.isRealTime = YES;
    
    decoder.orientation = UIImageOrientationUp;
    
    [decoder setupStream:[NSString stringWithFormat:@"%@/%@", hostTextField.text, streamTextField.text]];

    btnConnect.title = @"Disconnect";
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
        
        case STREAM_PLAYING: {
            
            if ([description isEqualToString:MP_NETSTREAM_PLAY_STREAM_NOT_FOUND]) {
                
                [self connectControl:nil];
                [self showAlert:description];
                
                break;
            }
            
            hostTextField.hidden = YES;
            streamTextField.hidden = YES;
            previewView.hidden = (decoder.videoCodecId == MP_VIDEO_CODEC_NONE);
            
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
