#import <React/RCTConvert.h>
#import "RNSkyWayPeer.h"



@implementation RNSkyWayPeer

- (void)dealloc
{
    [self disconnect];
}

- (instancetype)initWithPeerId:(NSString *)peerId options:(NSDictionary *)options constraints: (NSDictionary *)constraints
{
    self = [super init];
    if (self) {

        _peerStatus = RNSkyWayPeerDisconnected;
        _mediaConnectionStatus = RNSkyWayMediaConnectionDisconnected;

        _peerId = peerId;
        [self setOptionsFromDic:options];
        [self setConstraintsFromDic:constraints];
        _delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)setPeerStatus:(RNSkyWayPeerStatus)status {
    if (_peerStatus != status) {
        _peerStatus = status;
        [self notifyPeerStatusChangeDelegate];
    }
}

- (void)setMediaConnectionStatus:(RNSkyWayMediaConnectionStatus)status {
    if (_mediaConnectionStatus != status) {
        _mediaConnectionStatus = status;
        [self notifyMediaConnectionStatusChangeDelegate];
    }
}

- (void)setOptionsFromDic:(NSDictionary *)dic {
    _options = [[SKWPeerOption alloc] init];

    if ([dic objectForKey:@"key"] != nil) {
        _options.key = [RCTConvert NSString:dic[@"key"]];
    }
    if ([dic objectForKey:@"domain"] != nil) {
        _options.domain = [RCTConvert NSString:dic[@"domain"]];
    }
    if ([dic objectForKey:@"host"] != nil) {
        _options.host = [RCTConvert NSString:dic[@"host"]];
    }
    if ([dic objectForKey:@"port"] != nil) {
        _options.port = [RCTConvert NSInteger:dic[@"port"]];
    }
    if ([dic objectForKey:@"secure"] != nil) {
        _options.secure = [RCTConvert BOOL:dic[@"secure"]];
    }
    if ([dic objectForKey:@"turn"] != nil) {
        _options.turn = [RCTConvert BOOL:dic[@"turn"]];
    }
    if ([dic objectForKey:@"credential"] != nil) {
        NSDictionary *creDic = [RCTConvert NSDictionary:dic[@"credential"]];
        _options.credential = [[SKWPeerCredential alloc] init];
        _options.credential.ttl = [RCTConvert NSUInteger:creDic[@"ttl"]];
        _options.credential.timestamp = [RCTConvert NSUInteger:creDic[@"timestamp"]];
        _options.credential.authToken = [RCTConvert NSString:creDic[@"authToken"]];
    }
    // TODO: support `config`
}

- (void)setConstraintsFromDic:(NSDictionary *)dic {
    _constraints = [[SKWMediaConstraints alloc] init];

    if ([dic objectForKey:@"videoFlag"] != nil) {
        _constraints.videoFlag = [RCTConvert BOOL:dic[@"videoFlag"]];
    }
    if ([dic objectForKey:@"audioFlag"] != nil) {
        _constraints.videoFlag = [RCTConvert BOOL:dic[@"audioFlag"]];
    }
    if ([dic objectForKey:@"cameraPosition"] != nil) {
        _constraints.cameraPosition = [RCTConvert NSInteger:dic[@"cameraPosition"]];
    }
    if ([dic objectForKey:@"maxWidth"] != nil) {
        _constraints.maxWidth = [RCTConvert NSInteger:dic[@"maxWidth"]];
    }
    if ([dic objectForKey:@"minWidth"] != nil) {
        _constraints.minWidth = [RCTConvert NSInteger:dic[@"minWidth"]];
    }
    if ([dic objectForKey:@"maxHeight"] != nil) {
        _constraints.maxHeight = [RCTConvert NSInteger:dic[@"maxHeight"]];
    }
    if ([dic objectForKey:@"minHeight"] != nil) {
        _constraints.minHeight = [RCTConvert NSInteger:dic[@"minHeight"]];
    }
    if ([dic objectForKey:@"maxFrameRate"] != nil) {
        _constraints.maxFrameRate = [RCTConvert NSInteger:dic[@"maxFrameRate"]];
    }
    if ([dic objectForKey:@"minFrameRate"] != nil) {
        _constraints.minFrameRate = [RCTConvert NSInteger:dic[@"minFrameRate"]];
    }
}

- (void)connect {

    self.peer = [[SKWPeer alloc] initWithId:self.peerId options:self.options];
    __weak RNSkyWayPeer *weakSelf = self;

    [self.peer on:SKW_PEER_EVENT_OPEN callback:^(NSObject* obj) {
        NSLog(@"RNSkyWayPeerManager open");

        weakSelf.peerStatus = RNSkyWayPeerConnected;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyPeerOpenDelegate];
        });
    }];

    [self.peer on:SKW_PEER_EVENT_CLOSE callback:^(NSObject* obj) {
        NSLog(@"RNSkyWayPeerManager close");

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyPeerCloseDelegate];
        });
    }];

    [self.peer on:SKW_PEER_EVENT_DISCONNECTED callback:^(NSObject* obj) {
        NSLog(@"RNSkyWayPeerManager disconnected");

        [weakSelf disconnect];

        weakSelf.peerStatus = RNSkyWayPeerDisconnected;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyPeerDisconnectedDelegate];
        });
    }];


    [self.peer on:SKW_PEER_EVENT_ERROR callback:^(NSObject* obj) {
        NSLog(@"RNSkyWayPeerManager error");

        SKWPeerError* error = (SKWPeerError*)obj;
        NSLog(@"%@",error);

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyPeerErrorDelegate];
        });
    }];

    [self.peer on:SKW_PEER_EVENT_CALL callback:^(NSObject* obj) {
        NSLog(@"RNSkyWayPeerManager call");

        if (YES == [obj isKindOfClass:[SKWMediaConnection class]]) {
            weakSelf.mediaConnection = (SKWMediaConnection *)obj;
            [weakSelf setMediaCallbacks];

            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf notifyPeerCallDelegate];
            });
        }
    }];
}

- (void)disconnect {
    [self closeRemoteStream];
    [self closeLocalStream];
    [self closeMediaConnection];

    if (self.peer != nil) {
        [self unsetPeerCallbacks];

        if (![self.peer isDisconnected]) {
            [self.peer disconnect];
            [self notifyPeerDisconnectedDelegate];
        }
        [self.peer destroy];
    }
    self.peerStatus = RNSkyWayPeerDisconnected;
    self.peer = nil;
}

- (void)call:(NSString *)peerId {
    if (self.peer == nil) {
        return;
    }
    if (self.localStream == nil) {
        [self openLocalStream];
    }

    self.mediaConnection = [self.peer callWithId:peerId stream:self.localStream];
    [self setMediaCallbacks];
}

- (void)answer {
    if (self.peer == nil) {
        return;
    }
    if (self.mediaConnection == nil) {
        return;
    }

    if (self.localStream == nil) {
        [self openLocalStream];
    }

    [self.mediaConnection answer:self.localStream];
}

- (void)hangup {
    [self closeRemoteStream];
    [self closeLocalStream];
    [self closeMediaConnection];
}

- (void)joinRoom:(NSString *)roomId {
    if (nil == self.peer || nil != self.sfuRoom){
        return;
    }
    if (self.localStream == nil) {
        [self openLocalStream];
    }

    //
    // Join to a MeshRoom
    //
    SKWRoomOption* option = [[SKWRoomOption alloc] init];
    option.mode = SKW_ROOM_MODE_SFU;
    option.stream = self.localStream;
    self.sfuRoom = (SKWSFURoom*)[self.peer joinRoomWithName:roomId options:option];

    __weak RNSkyWayPeer *weakSelf = self;

    //
    // Set callbacks for ROOM_EVENTs
    //
    [self.sfuRoom on:SKW_ROOM_EVENT_OPEN callback:^(NSObject* arg) {
        NSString* roomName = (NSString*)arg;
        NSLog(@"SKW_ROOM_EVENT_OPEN: %@", roomName);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyRoomOpenDelegate];
        });
    }];
    [self.sfuRoom on:SKW_ROOM_EVENT_PEER_JOIN callback:^(NSObject* arg) {
        NSString* peerId_ = (NSString*)arg;
        NSLog(@"SKW_ROOM_EVENT_PEER_JOIN: %@", peerId_);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyRoomPeerJoinDelegate];
        });
    }];
    [self.sfuRoom on:SKW_ROOM_EVENT_PEER_LEAVE callback:^(NSObject* arg) {
        NSString* peerId_ = (NSString*)arg;
        NSLog(@"SKW_ROOM_EVENT_PEER_LEAVE: %@", peerId_);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyRoomPeerLeaveDelegate];
        });
    }];
    [self.sfuRoom on:SKW_ROOM_EVENT_LOG callback:^(NSObject* arg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyRoomLogDelegate];
        });
    }];
    [self.sfuRoom on:SKW_ROOM_EVENT_STREAM callback:^(NSObject* arg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyRoomStreamDelegate];
        });
    }];
    [self.sfuRoom on:SKW_ROOM_EVENT_REMOVE_STREAM callback:^(NSObject* arg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyRoomRemoveStreamDelegate];
        });
    }];
    [self.sfuRoom on:SKW_ROOM_EVENT_DATA callback:^(NSObject* arg) {
        SKWRoomDataMessage* msg = (SKWRoomDataMessage*)arg;
        NSString* peerId_ = msg.src;
        if ([msg.data isKindOfClass:[NSString class]]) {
            NSString* data = (NSString*)msg.data;
            NSLog(@"SKW_ROOM_EVENT_DATA(string): sender=%@, data=%@", peerId_, data);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyRoomDataDelegate];
        });
    }];
    [self.sfuRoom on:SKW_ROOM_EVENT_CLOSE callback:^(NSObject* arg) {
        NSString* roomName = (NSString*)arg;
        NSLog(@"SKW_ROOM_EVENT_CLOSE: %@", roomName);
        [self.sfuRoom offAll];
        self.sfuRoom = nil;

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyRoomCloseDelegate];
        });
    }];
    [self.sfuRoom on:SKW_ROOM_EVENT_ERROR callback:^(NSObject* arg) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyRoomErrorDelegate];
        });
    }];
}

- (void)leaveRoom {
    if (nil == self.peer || nil == self.sfuRoom){
        return;
    }
    [self.sfuRoom close];
}

- (void)switchCamera {
    if (self.peer == nil) {
        return;
    }
    if (self.localStream == nil) {
        return;
    }

    //BOOL result = [self.localStream switchCamera];
    BOOL result = NO;
    if ([self.localStream getCameraPosition] == SKW_CAMERA_POSITION_BACK) {
        result = [self.localStream setCameraPosition:SKW_CAMERA_POSITION_FRONT];
    } else if ([self.localStream getCameraPosition] == SKW_CAMERA_POSITION_FRONT) {
        result = [self.localStream setCameraPosition:SKW_CAMERA_POSITION_BACK];
    }
    if (result) {
        NSLog(@"RNSkyWayPeerManager switchCamera ok");
    } else {
        NSLog(@"RNSkyWayPeerManager switchCamera ng");
    }
}

- (void)setLocalStreamStatus:(BOOL *)status {
    if (self.peer == nil) {
        return;
    }
    if (self.localStream == nil) {
        return;
    }
    [self.localStream setEnableAudioTrack:0 enable:status];
}

- (void) openLocalStream {
    if (self.peer == nil) {
        return;
    }

    [self closeLocalStream];
    [SKWNavigator initialize:self.peer];
    self.localStream = [SKWNavigator getUserMedia:self.constraints];
    [SKWNavigator terminate];

    [self notifyLocalStreamOpenDelegate];
}

- (void) closeLocalStream {
    if(self.localStream == nil) {
        return;
    }

    [self notifyLocalStreamWillCloseDelegate];

    [self.localStream close];
    self.localStream = nil;
}

- (void) closeRemoteStream {
    if(self.remoteStream == nil) {
        return;
    }

    [self notifyRemoteStreamWillCloseDelegate];

    [self.remoteStream close];
    self.remoteStream = nil;
}

- (void)listAllPeers:(RCTResponseSenderBlock) callback {
    if (self.peer == nil) {
        callback(@[ @"Peer Disconnected", [NSNull null] ]);
        return;
    }

    [self.peer listAllPeers:^(NSArray* peers){
        callback(@[ [NSNull null], peers ]);
    }];
}

- (void)setMediaCallbacks {
    if (nil == self.mediaConnection) {
        return;
    }

    __weak RNSkyWayPeer *weakSelf = self;

    [_mediaConnection on:SKW_MEDIACONNECTION_EVENT_STREAM callback:^(NSObject* obj) {
        if (YES == [obj isKindOfClass:[SKWMediaStream class]]) {
            if (weakSelf.mediaConnectionStatus == RNSkyWayMediaConnectionConnected) {
                return;
            }

            weakSelf.mediaConnectionStatus = RNSkyWayMediaConnectionConnected;
            weakSelf.remoteStream = (SKWMediaStream *)obj;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf notifyMediaConnectionOpenDelegate];
                [weakSelf notifyRemoteStreamOpenDelegate];
            });
        }
    }];

    [_mediaConnection on:SKW_MEDIACONNECTION_EVENT_ERROR callback:^(NSObject* obj) {
        NSLog(@"RNSkyWayPeerManager mediaConnection error");

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyMediaConnectionErrorDelegate];
        });
    }];

    [_mediaConnection on:SKW_MEDIACONNECTION_EVENT_CLOSE callback:^(NSObject* obj) {
        NSLog(@"RNSkyWayPeerManager mediaConnection close");

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf notifyMediaConnectionCloseDelegate];
        });
    }];

}

- (void)closeMediaConnection {
    if (self.mediaConnection == nil) {
        return;
    };

    [self unsetMediaCallbacks];
    if ([self.mediaConnection isOpen]) {
        [self.mediaConnection close];
        [self notifyMediaConnectionCloseDelegate];
    }
    self.mediaConnectionStatus = RNSkyWayMediaConnectionDisconnected;
    self.mediaConnection = nil;
}

- (void)unsetPeerCallbacks {
    if (self.peer == nil) {
        return;
    }

    [self.peer on:SKW_PEER_EVENT_OPEN callback:nil];
    [self.peer on:SKW_PEER_EVENT_CONNECTION callback:nil];
    [self.peer on:SKW_PEER_EVENT_CALL callback:nil];
    [self.peer on:SKW_PEER_EVENT_CLOSE callback:nil];
    [self.peer on:SKW_PEER_EVENT_DISCONNECTED callback:nil];
    [self.peer on:SKW_PEER_EVENT_ERROR callback:nil];
}

- (void)unsetMediaCallbacks {
    if(self.mediaConnection == nil) {
        return;
    }

    [self.mediaConnection on:SKW_MEDIACONNECTION_EVENT_STREAM callback:nil];
    [self.mediaConnection on:SKW_MEDIACONNECTION_EVENT_CLOSE callback:nil];
    [self.mediaConnection on:SKW_MEDIACONNECTION_EVENT_ERROR callback:nil];
}


- (void) addDelegate: (id<RNSkyWayPeerDelegate>) delegate
{
    [self.delegates addObject: delegate];
}

- (void) removeDelegate: (id<RNSkyWayPeerDelegate>) delegate
{
    [self.delegates removeObject: delegate];
}

- (void) notifyPeerOpenDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onPeerOpen:)]) {
                [delegete onPeerOpen:self];
            }
        }
    }
}

- (void) notifyPeerCallDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onPeerCall:)]) {
                [delegete onPeerCall:self];
            }
        }
    }
}

- (void) notifyPeerCloseDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onPeerClose:)]) {
                [delegete onPeerClose:self];
            }
        }
    }
}

- (void) notifyPeerDisconnectedDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onPeerDisconnected:)]) {
                [delegete onPeerDisconnected:self];
            }
        }
    }
}

- (void) notifyPeerErrorDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onPeerError:)]) {
                [delegete onPeerError:self];
            }
        }
    }
}

- (void) notifyLocalStreamOpenDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onLocalStreamOpen:)]) {
                [delegete onLocalStreamOpen:self];
            }
        }
    }
}

- (void) notifyLocalStreamWillCloseDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onLocalStreamWillClose:)]) {
                [delegete onLocalStreamWillClose:self];
            }
        }
    }
}

- (void) notifyRemoteStreamOpenDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRemoteStreamOpen:)]) {
                [delegete onRemoteStreamOpen:self];
            }
        }
    }
}

- (void) notifyRemoteStreamWillCloseDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRemoteStreamWillClose:)]) {
                [delegete onRemoteStreamWillClose:self];
            }
        }
    }
}

- (void) notifyMediaConnectionOpenDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onMediaConnectionOpen:)]) {
                [delegete onMediaConnectionOpen:self];
            }
        }
    }
}

- (void) notifyMediaConnectionCloseDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onMediaConnectionClose:)]) {
                [delegete onMediaConnectionClose:self];
            }
        }
    }
}

- (void) notifyMediaConnectionErrorDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onMediaConnectionError:)]) {
                [delegete onMediaConnectionError:self];
            }
        }
    }
}


- (void) notifyPeerStatusChangeDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onPeerStatusChange:)]) {
                [delegete onPeerStatusChange:self];
            }
        }
    }
}

- (void) notifyMediaConnectionStatusChangeDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onMediaConnectionStatusChange:)]) {
                [delegete onMediaConnectionStatusChange:self];
            }
        }
    }
}

- (void) notifyRoomOpenDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRoomOpen:)]) {
                [delegete onRoomOpen:self];
            }
        }
    }
}

- (void) notifyRoomPeerJoinDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRoomPeerJoin:)]) {
                [delegete onRoomPeerJoin:self];
            }
        }
    }
}

- (void) notifyRoomPeerLeaveDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRoomPeerLeave:)]) {
                [delegete onRoomPeerLeave:self];
            }
        }
    }
}

- (void) notifyRoomLogDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRoomLog:)]) {
                [delegete onRoomLog:self];
            }
        }
    }
}

- (void) notifyRoomStreamDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRoomStream:)]) {
                [delegete onRoomStream:self];
            }
        }
    }
}

- (void) notifyRoomRemoveStreamDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRoomRemoveStream:)]) {
                [delegete onRoomRemoveStream:self];
            }
        }
    }
}

- (void) notifyRoomDataDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRoomData:)]) {
                [delegete onRoomData:self];
            }
        }
    }
}

- (void) notifyRoomCloseDelegate {
    if (self.peer == nil) {
        return;
    }
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRoomClose:)]) {
                [delegete onRoomClose:self];
            }
        }
    }
}

- (void) notifyRoomErrorDelegate {
    for (id<RNSkyWayPeerDelegate> delegete in self.delegates) {
        if ([delegete conformsToProtocol:@protocol(RNSkyWayPeerDelegate)]) {
            if ([delegete respondsToSelector:@selector(onRoomError:)]) {
                [delegete onRoomError:self];
            }
        }
    }
}

@end
