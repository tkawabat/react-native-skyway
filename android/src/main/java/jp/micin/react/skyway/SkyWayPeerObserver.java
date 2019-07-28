package jp.micin.react.skyway;


public interface SkyWayPeerObserver {
  void onPeerOpen(SkyWayPeer peer);
  void onPeerCall(SkyWayPeer peer);
  void onPeerClose(SkyWayPeer peer);
  void onPeerDisconnected(SkyWayPeer peer);
  void onPeerError(SkyWayPeer peer);
  void onLocalStreamOpen(SkyWayPeer peer);
  void onLocalStreamWillClose(SkyWayPeer peer);
  void onRemoteStreamOpen(SkyWayPeer peer);
  void onRemoteStreamWillClose(SkyWayPeer peer);
  void onMediaConnectionOpen(SkyWayPeer peer);
  void onMediaConnectionClose(SkyWayPeer peer);
  void onMediaConnectionError(SkyWayPeer peer);
  void onPeerStatusChange(SkyWayPeer peer);
  void onMediaConnectionStatusChange(SkyWayPeer peer);
  void onRoomOpen(SkyWayPeer peer);
  void onRoomPeerJoin(SkyWayPeer peer);
  void onRoomPeerLeave(SkyWayPeer peer);
  void onRoomLog(SkyWayPeer peer);
  void onRoomStream(SkyWayPeer peer);
  void onRoomRemoveStream(SkyWayPeer peer);
  void onRoomData(SkyWayPeer peer);
  void onRoomClose(SkyWayPeer peer);
  void onRoomError(SkyWayPeer peer);
}
