
#import "RNSkyWayPeerManager.h"
#import "RNSkyWayPeer.h"

@implementation RNSkyWayPeerManager

@synthesize bridge = _bridge;

- (void)dealloc
{
    [_peers removeAllObjects];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _peers = [NSMutableDictionary new];
    }
    return self;
}

- (RNSkyWayPeer *)peerById:(NSString *)peerId {
    return _peers[peerId];
}


RCT_EXPORT_METHOD(create:(nonnull NSString *)peerId
                  options:(NSDictionary *)options
                  constraints:(NSDictionary *)constraints)
{
    NSLog(@"RNSkyWayPeerManager create");
    
    RNSkyWayPeer *peer = [[RNSkyWayPeer alloc] initWithPeerId:peerId options:options constraints:constraints];
    self.peers[peerId] = peer;
    [peer addDelegate:self];
}

RCT_EXPORT_METHOD(connect:(nonnull NSString *)peerId)
{
    NSLog(@"RNSkyWayPeerManager connect");
    
    [self.peers[peerId] connect];
}

RCT_EXPORT_METHOD(disconnect:(nonnull NSString *)peerId)
{
    NSLog(@"RNSkyWayPeerManager disconnect");
    
    [self.peers[peerId] disconnect];
}


RCT_EXPORT_METHOD(dispose:(nonnull NSString *)peerId)
{
    NSLog(@"RNSkyWayPeerManager dispose");
    
    [self.peers[peerId] disconnect];
    [self.peers removeObjectForKey:peerId];
}


RCT_EXPORT_METHOD(listAllPeers:(nonnull NSString *)peerId
                  callback:(RCTResponseSenderBlock)callback)
{
    NSLog(@"RNSkyWayPeerManager listAll");
    
    [self.peers[peerId] listAllPeers:callback];
}

RCT_EXPORT_METHOD(call:(nonnull NSString *)peerId
                  targetPeerId:(nonnull NSString *)targetPeerId)
{
    NSLog(@"RNSkyWayPeerManager call");
    
    [self.peers[peerId] call:targetPeerId];
}

RCT_EXPORT_METHOD(answer:(nonnull NSString *)peerId)
{
    NSLog(@"RNSkyWayPeerManager answer");
    
    [self.peers[peerId] answer];
}

RCT_EXPORT_METHOD(hangup:(nonnull NSString *)peerId)
{
    NSLog(@"RNSkyWayPeerManager hangup");
    
    [self.peers[peerId] hangup];
}

RCT_EXPORT_METHOD(joinRoom:(nonnull NSString *)peerId
                  roomId:(nonnull NSString *)roomId)
{
    NSLog(@"RNSkyWayPeerManager joinRoom");
    
    [self.peers[peerId] joinRoom:roomId];
}

RCT_EXPORT_METHOD(leaveRoom:(nonnull NSString *)peerId)
{
    NSLog(@"RNSkyWayPeerManager leaveRoom");
    
    [self.peers[peerId] leaveRoom];
}

RCT_EXPORT_METHOD(switchCamera:(nonnull NSString *)peerId)
{
    NSLog(@"RNSkyWayPeerManager switchCamera");

    [self.peers[peerId] switchCamera];
}

RCT_EXPORT_MODULE(SkyWayPeerManager);

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (NSArray<NSString *> *)supportedEvents {
    return @[
             @"SkyWayPeerOpen",
             @"SkyWayPeerCall",
             @"SkyWayPeerClose",
             @"SkyWayPeerDisconnected",
             @"SkyWayPeerError",
             @"SkyWayMediaConnectionOpen",
             @"SkyWayMediaConnectionClose",
             @"SkyWayMediaConnectionError",
             @"SkyWayPeerStatusChange",
             @"SkyWayMediaConnectionStatusChange",
             @"SkyWayRoomOpen",
             @"SkyWayRoomPeerJoin",
             @"SkyWayRoomPeerLeave",
             @"SkyWayRoomLog",
             @"SkyWayRoomStream",
             @"SkyWayRoomRemoveStream",
             @"SkyWayRoomData",
             @"SkyWayRoomClose",
             @"SkyWayRoomError"
             ];
}

-(void)onPeerOpen:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayPeerOpen" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onPeerCall:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayPeerCall" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onPeerClose:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayPeerClose" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onPeerDisconnected:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayPeerDisconnected" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onPeerError:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayPeerError" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onMediaConnectionOpen:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayMediaConnectionOpen" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onMediaConnectionClose:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayMediaConnectionClose" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onMediaConnectionError:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayMediaConnectionError" body:@{@"peer": @{@"id": peer.peer.identity}}];
}

-(void)onPeerStatusChange:(RNSkyWayPeer *)peer {
    NSNumber *status = [NSNumber numberWithInt: peer.peerStatus];
    [self sendEventWithName:@"SkyWayPeerStatusChange" body:@{@"peer": @{@"id": peer.peer.identity}, @"status": status}];
}
-(void)onMediaConnectionStatusChange:(RNSkyWayPeer *)peer {
    NSNumber *status = [NSNumber numberWithInt: peer.mediaConnectionStatus];
    [self sendEventWithName:@"SkyWayMediaConnectionStatusChange" body:@{@"peer": @{@"id": peer.peer.identity}, @"status": status}];
}

-(void)onRoomOpen:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayRoomOpen" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onRoomPeerJoin:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayRoomPeerJoin" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onRoomPeerLeave:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayRoomPeerLeave" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onRoomLog:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayRoomLog" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onRoomStream:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayRoomStream" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onRoomRemoveStream:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayRoomRemoveStream" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onRoomData:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayRoomData" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onRoomClose:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayRoomClose" body:@{@"peer": @{@"id": peer.peer.identity}}];
}
-(void)onRoomError:(RNSkyWayPeer *)peer {
    [self sendEventWithName:@"SkyWayRoomError" body:@{@"peer": @{@"id": peer.peer.identity}}];
}

@end
