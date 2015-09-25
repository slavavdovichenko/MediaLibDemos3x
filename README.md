MediaLibDemos3x
===============

Media Library for iOS provides the classes and protocols for media live stream publishing and playback, or VOD recording and playback, via RTMP.
It allows the iOS devices to interact with the media servers: Adobe FMS, Wowza MS, Red5, crtmp, rtmpd.

Video codecs: H264, H.263 (Sorenson)
Audio codecs: AAC, Speex, Nelly Moser

Media Library for iOS uses the classes and protocols of Communication Library for iOS (see Communication Library for iOS User Guide).

Requirements
The library imposes the following requirements on the iOS applications utilizing it:
1. iOS Deployment Target - 7.1 or above;
2. The following frameworks and libraries must be added to the list of libraries linked to the binary:
-	CoreData.framework, SystemConfiguration.framework, libsqlite3.tbd, libz.tbd;
-	The Midnight Coders static library: CommLibiOS.a;
-	FFmpeg/libav static libraries: libavcodec.a, libavdevice.a, libavfilter.a, libavformat.a, libavutil.a, libswscale.a;
-   x264 static library: libx264.a;
-   speex static librariy: libspeex.a

Add the Libraries and Frameworks to the project

1. Choose the project target, go to Build Phases->Link Binary With Libraries, push “+”, check the following iOS frameworks and libraries: CoreData.framework, SystemConfiguration.framework, libsqlite3.tbd, libz.tbd. Push “Add” button.
2. Add the folder “lib” from Backendless SDK kit to the your project folder.
3. Mark the project and choose File- > ”Add Files to …” menu item. In window choose the “lib” folder in the project folder. Make sure that the “Add to targets” checkbox must be checked. Push “Add” button.
4. Add the following option to the Build Settings -> Search Paths -> Library Search Paths line:

$(inherited) $(PROJECT_DIR)/lib/backendless $(PROJECT_DIR)/lib/CommLibiOS $(PROJECT_DIR)/lib/libav-11.4/lib $(PROJECT_DIR)/lib/MediaLibiOS3x $(PROJECT_DIR)/lib/speex-1.2rc2/lib $(PROJECT_DIR)/lib/x264/lib

