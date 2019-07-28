
#ifndef RNSkyWayPeerDelegate_h
#define RNSkyWayPeerDelegate_h

@class RNSkyWayPeer;

@protocol RNSkyWayPeerDelegate <NSObject>
@optional
-(void)onPeerOpen:(RNSkyWayPeer *)peer;
-(void)onPeerCall:(RNSkyWayPeer *)peer;
-(void)onPeerClose:(RNSkyWayPeer *)peer;
-(void)onPeerDisconnected:(RNSkyWayPeer *)peer;
-(void)onPeerError:(RNSkyWayPeer *)peer;
-(void)onLocalStreamOpen:(RNSkyWayPeer *)peer;
-(void)onLocalStreamWillClose:(RNSkyWayPeer *)peer;
-(void)onRemoteStreamOpen:(RNSkyWayPeer *)peer;
-(void)onRemoteStreamWillClose:(RNSkyWayPeer *)peer;
-(void)onMediaConnectionOpen:(RNSkyWayPeer *)peer;
-(void)onMediaConnectionClose:(RNSkyWayPeer *)peer;
-(void)onMediaConnectionError:(RNSkyWayPeer *)peer;
-(void)onPeerStatusChange:(RNSkyWayPeer *)peer;
-(void)onMediaConnectionStatusChange:(RNSkyWayPeer *)peer;
-(void)onRoomOpen:(RNSkyWayPeer *)peer;
-(void)onRoomPeerJoin:(RNSkyWayPeer *)peer;
-(void)onRoomPeerLeave:(RNSkyWayPeer *)peer;
-(void)onRoomLog:(RNSkyWayPeer *)peer;
-(void)onRoomStream:(RNSkyWayPeer *)peer;
-(void)onRoomRemoveStream:(RNSkyWayPeer *)peer;
-(void)onRoomData:(RNSkyWayPeer *)peer;
-(void)onRoomClose:(RNSkyWayPeer *)peer;
-(void)onRoomError:(RNSkyWayPeer *)peer;

@end

#endif /* RNSkyWayPeerDelegate_h */
