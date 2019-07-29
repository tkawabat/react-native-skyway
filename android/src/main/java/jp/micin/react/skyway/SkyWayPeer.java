package jp.micin.react.skyway;


import android.content.Context;
import android.util.Log;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.UiThreadUtil;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableNativeArray;

import org.json.JSONArray;

import java.util.ArrayList;

import io.skyway.Peer.Browser.MediaConstraints;
import io.skyway.Peer.Browser.MediaStream;
import io.skyway.Peer.Browser.Navigator;
import io.skyway.Peer.CallOption;
import io.skyway.Peer.MediaConnection;
import io.skyway.Peer.OnCallback;
import io.skyway.Peer.Peer;
import io.skyway.Peer.PeerCredential;
import io.skyway.Peer.PeerError;
import io.skyway.Peer.PeerOption;
import io.skyway.Peer.Room;
import io.skyway.Peer.RoomDataMessage;
import io.skyway.Peer.RoomOption;




public class SkyWayPeer {

  static final String TAG = SkyWayPeer.class.getCanonicalName();

  private Context context;

  private String peerId;
  private PeerOption options;
  private MediaConstraints constraints;

  private Peer peer;
  private Room room;
  private MediaStream	localStream;
  private MediaStream	remoteStream;
  private MediaConnection	mediaConnection;

  private SkyWayPeerStatus peerStatus;

  private SkyWayMediaConnectionStatus mediaConnectionStatus;


  private ArrayList<SkyWayPeerObserver> observers;


  public String getPeerId() {
    return peerId;
  }

  public Peer getPeer() {
    return peer;
  }

  public MediaStream getLocalStream() {
    return localStream;
  }

  public MediaStream getRemoteStream() {
    return remoteStream;
  }

  public MediaConnection getMediaConnection() {
    return mediaConnection;
  }

  public SkyWayPeerStatus getPeerStatus() {
    return peerStatus;
  }

  public void setPeerStatus(SkyWayPeerStatus peerStatus) {
    if (this.peerStatus != peerStatus) {
      this.peerStatus = peerStatus;
      notifyOnPeerStatusChange();
    }
  }

  public SkyWayMediaConnectionStatus getMediaConnectionStatus() {
    return mediaConnectionStatus;
  }

  public void setMediaConnectionStatus(SkyWayMediaConnectionStatus mediaConnectionStatus) {
    if (this.mediaConnectionStatus != mediaConnectionStatus) {
      this.mediaConnectionStatus = mediaConnectionStatus;
      notifyOnMediaConnectionStatusChange();
    }
  }


  public SkyWayPeer(Context context, String peerId, ReadableMap options, ReadableMap constraints) {
    this.context = context;
    this.peerId = peerId;
    this.options = convertOptionsFromMap(options);
    this.constraints = convertConstraintsFromMap(constraints);

    this.observers = new ArrayList<SkyWayPeerObserver>();
  }

  private PeerOption convertOptionsFromMap(ReadableMap map) {
    PeerOption options = new PeerOption();

    if (map.hasKey("key")) {
      options.key = map.getString("key");
    }
    if (map.hasKey("domain")) {
      options.domain = map.getString("domain");
    }
    if (map.hasKey("host")) {
      options.host = map.getString("host");
    }
    if (map.hasKey("port")) {
      options.port = map.getInt("port");
    }
    if (map.hasKey("secure")) {
      options.secure = map.getBoolean("secure");
    }
    if (map.hasKey("turn")) {
      options.turn = map.getBoolean("turn");
    }
    if (map.hasKey("credential")) {
      ReadableMap creMap = map.getMap("credential");
      options.credential = new PeerCredential();
      options.credential.ttl = creMap.getInt("ttl");
      options.credential.timestamp = creMap.getInt("timestamp");
      options.credential.authToken = creMap.getString("authToken");
    }

    // TODO: support `config`

    return options;
  }


  private MediaConstraints convertConstraintsFromMap(ReadableMap map) {
    MediaConstraints constraints = new MediaConstraints();

    if (map.hasKey("videoFlag")) {
      constraints.videoFlag = map.getBoolean("videoFlag");
    }
    if (map.hasKey("audioFlag")) {
      constraints.audioFlag = map.getBoolean("audioFlag");
    }

    if (map.hasKey("cameraPosition")) {
      int ipos = map.getInt("cameraPosition");
      MediaConstraints.CameraPositionEnum pos = MediaConstraints.CameraPositionEnum.UNSPECIFIED;
      if (ipos == 1) {
        pos = MediaConstraints.CameraPositionEnum.BACK;
      }
      if (ipos == 1) {
        pos = MediaConstraints.CameraPositionEnum.FRONT;
      }
      constraints.cameraPosition = pos;
    }
    if (map.hasKey("maxWidth")) {
      constraints.maxWidth = map.getInt("maxWidth");
    }
    if (map.hasKey("minWidth")) {
      constraints.minWidth = map.getInt("minWidth");
    }
    if (map.hasKey("maxHeight")) {
      constraints.maxHeight = map.getInt("maxHeight");
    }
    if (map.hasKey("minHeight")) {
      constraints.minHeight = map.getInt("minHeight");
    }
    if (map.hasKey("maxFrameRate")) {
      constraints.maxFrameRate = map.getInt("maxFrameRate");
    }
    if (map.hasKey("minFrameRate")) {
      constraints.minFrameRate = map.getInt("minFrameRate");
    }

    return constraints;
  }


  public void dispose() {
    disconnect();
    observers.removeAll(observers);
  }

  public void connect() {
    disconnect();

    peer = new Peer(context, peerId, this.options);
    peer.on(Peer.PeerEventEnum.OPEN, new OnCallback() {
      @Override
      public void onCallback(Object object) {
        Log.d(TAG, "Peer OnOpen");

        setPeerStatus(SkyWayPeerStatus.Connected);
        notifyOnPeerOpen();
      }
    });

    peer.on(Peer.PeerEventEnum.DISCONNECTED, new OnCallback() {
      @Override
      public void onCallback(Object object) {
        Log.d(TAG, "Peer OnDisconnected");

        disconnect();

        setPeerStatus(SkyWayPeerStatus.Disconnected);
        notifyOnPeerDisconnected();
      }
    });

    peer.on(Peer.PeerEventEnum.CLOSE, new OnCallback()	{
      @Override
      public void onCallback(Object object) {
        Log.d(TAG, "Peer OnClose");

        notifyOnPeerClose();
      }
    });

    peer.on(Peer.PeerEventEnum.ERROR, new OnCallback() {
      @Override
      public void onCallback(Object object) {
        PeerError error = (PeerError) object;
        Log.d(TAG, "Peer OnError: " + error);

        notifyOnPeerError();
      }
    });

    peer.on(Peer.PeerEventEnum.CALL, new OnCallback() {
      @Override
      public void onCallback(Object object) {
        Log.d(TAG, "Peer OnCall");

        if (!(object instanceof MediaConnection)) {
          return;
        }

        mediaConnection = (MediaConnection) object;
        setMediaCallbacks();

        notifyOnPeerCall();
      }
    });

  }

  public void disconnect() {
    closeRemoteStream();
    closeLocalStream();
    closeMediaConnection();

    if (peer != null) {
      unsetPeerCallback();
      if (!peer.isDisconnected()) {
        peer.disconnect();
        notifyOnPeerDisconnected();
      }
      peer.destroy();
      setPeerStatus(SkyWayPeerStatus.Disconnected);
    }
    peer = null;
  }

  public void listAllPeers(final Callback callback) {
    if (peer == null) {
      callback.invoke("Peer Disconnected", null);
      return;
    }

    peer.listAllPeers(new OnCallback() {
      @Override
      public void onCallback(Object object) {
        if (!(object instanceof JSONArray)) {
          callback.invoke(null, null);
          return;
        }

        JSONArray peersJson = (JSONArray) object;
        WritableArray peers = new WritableNativeArray();

        for (int i = 0; i < peersJson.length();  ++i) {
          try {
            String peerId = peersJson.getString(i);
            peers.pushString(peerId);
          } catch (Exception e) {
            Log.e(TAG, e.toString());
          }
        }

        callback.invoke(null, peers);
      }

    });
  }

  public void call(String targetPeerId) {
    if (peer == null) {
      return;
    }

    if (localStream == null) {
      openLocalStream();
    }

    CallOption option = new CallOption();
    mediaConnection = peer.call(targetPeerId, localStream, option);
    if (mediaConnection != null) {
      this.setMediaCallbacks();
    }
  }

  public void answer() {
    if (peer == null) {
      return;
    }
    if (mediaConnection == null) {
      return;
    }

    if (localStream == null) {
      openLocalStream();
    }

    mediaConnection.answer(localStream);
  }


  public void hangup() {
    closeLocalStream();
    closeRemoteStream();
    closeMediaConnection();
  }

  public void joinRoom(String roomId) {
    if (peer == null) {
      return;
    }

    if (localStream == null) {
      openLocalStream();
    }

    RoomOption option = new RoomOption();
    option.mode = RoomOption.RoomModeEnum.SFU;
    option.stream = localStream;
    this.room = peer.joinRoom(roomId, option);

    this.room.on(Room.RoomEventEnum.OPEN, new OnCallback() {
        @Override
        public void onCallback(Object object) {
            if (!(object instanceof String)) return;

            String roomName = (String)object;
            Log.i(TAG, "Enter Room: " + roomName);
            notifyOnRoomOpen();
        }
    });

    this.room.on(Room.RoomEventEnum.PEER_JOIN, new OnCallback()    {
        @Override
        public void onCallback(Object object) {
            Log.d(TAG, "RoomEventEnum.PEER_JOIN:");

            if (!(object instanceof String)) return;

            final String peerId = (String)object;
            Log.i(TAG, "Join Room: " + peerId);
            notifyOnRoomPeerJoin();
        }
    });

    this.room.on(Room.RoomEventEnum.PEER_LEAVE, new OnCallback() {
        @Override
        public void onCallback(Object object) {
            Log.d(TAG, "RoomEventEnum.PEER_LEAVE:");

            if (!(object instanceof String)) return;

            String peerId = (String)object;
            Log.i(TAG, "Leave Room: " + peerId);
            notifyOnRoomPeerLeave();
        }
    });

    this.room.on(Room.RoomEventEnum.LOG, new OnCallback() {
        @Override
        public void onCallback(Object object) {
            if (!(object instanceof String)) return;
            notifyOnRoomLog();
        }
    });

    this.room.on(Room.RoomEventEnum.STREAM, new OnCallback() {
        @Override
        public void onCallback(Object object) {
            if (!(object instanceof String)) return;
            notifyOnRoomStream();
        }
    });

    this.room.on(Room.RoomEventEnum.REMOVE_STREAM, new OnCallback() {
        @Override
        public void onCallback(Object object) {
            if (!(object instanceof String)) return;
            notifyOnRoomRemoveStream();
        }
    });

    this.room.on(Room.RoomEventEnum.DATA, new OnCallback() {
        @Override
        public void onCallback(Object object) {
            if (!(object instanceof String)) return;
            notifyOnRoomData();
        }
    });

    this.room.on(Room.RoomEventEnum.CLOSE, new OnCallback() {
        @Override
        public void onCallback(Object object) {
            String roomName = (String)object;
            Log.i(TAG, "Leave Room: " + roomName);

            // Unset callbacks
            this.room.on(Room.RoomEventEnum.OPEN, null);
            this.room.on(Room.RoomEventEnum.PEER_JOIN, null);
            this.room.on(Room.RoomEventEnum.PEER_LEAVE, null);
            this.room.on(Room.RoomEventEnum.LOG, null);
            this.room.on(Room.RoomEventEnum.STREAM, null);
            this.room.on(Room.RoomEventEnum.REMOVE_STREAM, null);
            this.room.on(Room.RoomEventEnum.DATA, null);
            this.room.on(Room.RoomEventEnum.CLOSE, null);
            this.room.on(Room.RoomEventEnum.ERROR, null);

            this.room = null;
            notifyOnRoomClose();
        }
    });

    this.room.on(Room.RoomEventEnum.ERROR, new OnCallback()    {
        @Override
        public void onCallback(Object object) {
            PeerError error = (PeerError) object;
            Log.d(TAG, "RoomEventEnum.ERROR:" + error);
            notifyOnRoomError();
        }
    });

    if (mediaConnection != null) {
      this.setMediaCallbacks();
    }
  }

  public void leaveRoom() {
      if (null == this.peer || null == this.room) {
          return;
      }
      this.room.close();
  }

  public void switchCamera() {
    if (peer == null) {
      return;
    }
    if (localStream == null) {
      return;
    }

    localStream.switchCamera();
  }

  private void openLocalStream() {
    if (peer == null) {
      return;
    }

    closeLocalStream();
    Navigator.initialize(peer);
    localStream = Navigator.getUserMedia(constraints);
    Navigator.terminate();

    notifyOnLocalStreamOpen();
  }


  private void closeLocalStream() {
    if (localStream == null) {
      return;
    }

    notifyOnLocalStreamWillClose();

    localStream.close();
    localStream = null;
  }

  private void closeRemoteStream() {
    if (remoteStream == null) {
      return;
    }

    notifyOnRemoteStreamWillClose();

    remoteStream.close();
    remoteStream = null;
  }

  private void closeMediaConnection() {
    if (mediaConnection == null) {
      return;
    }

    unsetMediaCallbacks();
    if (mediaConnection.isOpen()) {
      mediaConnection.close();
      notifyOnMediaConnectionClose();
    }
    setMediaConnectionStatus(SkyWayMediaConnectionStatus.Disconnected);
    mediaConnection = null;

  }


  void setMediaCallbacks() {

    mediaConnection.on(MediaConnection.MediaEventEnum.STREAM, new OnCallback() {
      @Override
      public void onCallback(Object object) {
        Log.d(TAG, "MediaConnection Stream Open");

        closeRemoteStream();
        remoteStream = (MediaStream) object;

        setMediaConnectionStatus(SkyWayMediaConnectionStatus.Connected);
        notifyOnMediaConnectionOpen();
        notifyOnRemoteStreamOpen();
      }
    });

    mediaConnection.on(MediaConnection.MediaEventEnum.ERROR, new OnCallback()	{
      @Override
      public void onCallback(Object object) {
        PeerError error = (PeerError) object;
        Log.d(TAG, "MediaConnection OnError: " + error);

        notifyOnMediaConnectionError();
      }
    });

    mediaConnection.on(MediaConnection.MediaEventEnum.CLOSE, new OnCallback() {
      @Override
      public void onCallback(Object o) {
        Log.d(TAG, "MediaConnection Close");

        closeMediaConnection();

        setMediaConnectionStatus(SkyWayMediaConnectionStatus.Disconnected);
        notifyOnMediaConnectionClose();
      }
    });
  }

  void unsetPeerCallback() {
    if(peer == null){
      return;
    }

    peer.on(Peer.PeerEventEnum.OPEN, null);
    peer.on(Peer.PeerEventEnum.CONNECTION, null);
    peer.on(Peer.PeerEventEnum.CALL, null);
    peer.on(Peer.PeerEventEnum.CLOSE, null);
    peer.on(Peer.PeerEventEnum.DISCONNECTED, null);
    peer.on(Peer.PeerEventEnum.ERROR, null);
  }

  void unsetMediaCallbacks() {
    if(null == mediaConnection){
      return;
    }

    mediaConnection.on(MediaConnection.MediaEventEnum.STREAM, null);
    mediaConnection.on(MediaConnection.MediaEventEnum.CLOSE, null);
    mediaConnection.on(MediaConnection.MediaEventEnum.ERROR, null);
  }

  public void addObserver(SkyWayPeerObserver observer) {
    if(!observers.contains(observer)) {
      observers.add(observer);
    }
  }

  public void removeObserver(SkyWayPeerObserver observer) {
    if(observers.contains(observer)) {
      observers.remove(observer);
    }
  }

  private void notifyOnPeerOpen() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onPeerOpen(this);
    }
  }

  private void notifyOnPeerCall() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onPeerCall(this);
    }
  }

  private void notifyOnPeerClose() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onPeerClose(this);
    }
  }

  private void notifyOnPeerDisconnected() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onPeerDisconnected(this);
    }
  }

  private void notifyOnPeerError() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onPeerError(this);
    }
  }

  private void notifyOnLocalStreamOpen() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onLocalStreamOpen(this);
    }
  }

  private void notifyOnLocalStreamWillClose() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onLocalStreamWillClose(this);
    }
  }

  private void notifyOnRemoteStreamOpen() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRemoteStreamOpen(this);
    }
  }

  private void notifyOnRemoteStreamWillClose() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRemoteStreamWillClose(this);
    }
  }

  private void notifyOnMediaConnectionOpen() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onMediaConnectionOpen(this);
    }
  }

  private void notifyOnMediaConnectionClose() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onMediaConnectionClose(this);
    }
  }

  private void notifyOnMediaConnectionError() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onMediaConnectionError(this);
    }
  }

  private void notifyOnPeerStatusChange() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onPeerStatusChange(this);
    }
  }

  private void notifyOnMediaConnectionStatusChange() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onMediaConnectionStatusChange(this);
    }
  }

  private void notifyOnRoomOpen() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRoomOpen(this);
    }
  }

  private void notifyOnRoomPeerJoin() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRoomPeerJoin(this);
    }
  }

  private void notifyOnRoomPeerLeave() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRoomPeerLeave(this);
    }
  }

  private void notifyOnRoomLog() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRoomLog(this);
    }
  }

  private void notifyOnRoomStream() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRoomOpen(this);
    }
  }

  private void notifyOnRoomRemoveStream() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRoomRemoveStream(this);
    }
  }

  private void notifyOnRoomData() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRoomData(this);
    }
  }

  private void notifyOnRoomClose() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRoomClose(this);
    }
  }

  private void notifyOnRoomError() {
    for (SkyWayPeerObserver observer: observers) {
      observer.onRoomError(this);
    }
  }

}
