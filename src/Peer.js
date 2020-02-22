import {NativeEventEmitter, NativeModules} from 'react-native';
import EventTarget from 'event-target-shim';


const {SkyWayPeerManager} = NativeModules;
const skyWayPeerEventEmitter = new NativeEventEmitter(SkyWayPeerManager);

const PeerStatus = {
  Disconnected: 0,
  Connected: 1,
};

const MediaConnectionStatus = {
  Disconnected: 0,
  Connected: 1,
};

export class PeerEvent {
  constructor(type, eventInitDict) {
    this.type = type.toString();
    Object.assign(this, eventInitDict);
  }
}

export class Peer extends EventTarget {

  constructor(peerId, options, constraints) {
    super();

    this.onPeerOpen = this.onPeerOpen.bind(this);
    this.onPeerCall = this.onPeerCall.bind(this);
    this.onPeerClose = this.onPeerClose.bind(this);
    this.onPeerDisconnected = this.onPeerDisconnected.bind(this);
    this.onPeerError = this.onPeerError.bind(this);
    this.onMediaConnectionOpen = this.onMediaConnectionOpen.bind(this);
    this.onMediaConnectionClose = this.onMediaConnectionClose.bind(this);
    this.onMediaConnectionError = this.onMediaConnectionError.bind(this);

    this.onRoomOpen = this.onRoomOpen.bind(this);
    this.onRoomPeerJoin = this.onRoomPeerJoin.bind(this);
    this.onRoomPeerLeave = this.onRoomPeerLeave.bind(this);
    this.onRoomLog = this.onRoomLog.bind(this);
    this.onRoomStream = this.onRoomStream.bind(this);
    this.onRoomRemoveStream = this.onRoomRemoveStream.bind(this);
    this.onRoomData = this.onRoomData.bind(this);
    this.onRoomClose = this.onRoomClose.bind(this);
    this.onRoomError = this.onRoomError.bind(this);

    this._peerId = peerId;
    this._options = options || {};
    this._constraints = constraints || {};
    this._peerStatus = PeerStatus.Disconnected;
    this._mediaConnectionStatus = MediaConnectionStatus.Disconnected;
    this._disposed = false;

    this.init();
  }

  get peerId() {
    return this._peerId;
  }

  get options() {
    return this._options;
  }

  get constraints() {
    return this._constraints;
  }

  get peerStatus() {
    return this._peerStatus;
  }

  get mediaConnectionStatus() {
    return this._mediaConnectionStatus;
  }

  init() {
    SkyWayPeerManager.create(this._peerId, this._options, this._constraints);
    this.listen();
  }

  dispose() {
    SkyWayPeerManager.dispose(this._peerId);
    this.unlisten();

    this.disposed = true;
  }

  listen() {
    skyWayPeerEventEmitter.addListener('SkyWayPeerOpen', this.onPeerOpen);
    skyWayPeerEventEmitter.addListener('SkyWayPeerCall', this.onPeerCall);
    skyWayPeerEventEmitter.addListener('SkyWayPeerClose', this.onPeerClose);
    skyWayPeerEventEmitter.addListener('SkyWayPeerDisconnected', this.onPeerDisconnected);
    skyWayPeerEventEmitter.addListener('SkyWayPeerError', this.onPeerError);
    skyWayPeerEventEmitter.addListener('SkyWayMediaConnectionOpen', this.onMediaConnectionOpen);
    skyWayPeerEventEmitter.addListener('SkyWayMediaConnectionClose', this.onMediaConnectionClose);
    skyWayPeerEventEmitter.addListener('SkyWayMediaConnectionError', this.onMediaConnectionError);
    skyWayPeerEventEmitter.addListener('SkyWayRoomOpen', this.onRoomOpen);
    skyWayPeerEventEmitter.addListener('SkyWayRoomPeerJoin', this.onRoomPeerJoin);
    skyWayPeerEventEmitter.addListener('SkyWayRoomPeerLeave', this.onRoomPeerLeave);
    skyWayPeerEventEmitter.addListener('SkyWayRoomLog', this.onRoomLog);
    skyWayPeerEventEmitter.addListener('SkyWayRoomStream', this.onRoomStream);
    skyWayPeerEventEmitter.addListener('SkyWayRoomRemoveStream', this.onRoomRemoveStream);
    skyWayPeerEventEmitter.addListener('SkyWayRoomData', this.onRoomData);
    skyWayPeerEventEmitter.addListener('SkyWayRoomClose', this.onRoomClose);
    skyWayPeerEventEmitter.addListener('SkyWayRoomError', this.onRoomError);
  }

  unlisten() {
    skyWayPeerEventEmitter.removeListener('SkyWayPeerOpen', this.onPeerOpen);
    skyWayPeerEventEmitter.removeListener('SkyWayPeerCall', this.onPeerCall);
    skyWayPeerEventEmitter.removeListener('SkyWayPeerClose', this.onPeerClose);
    skyWayPeerEventEmitter.removeListener('SkyWayPeerDisconnected', this.onPeerDisconnected);
    skyWayPeerEventEmitter.removeListener('SkyWayPeerError', this.onPeerError);
    skyWayPeerEventEmitter.removeListener('SkyWayMediaConnectionOpen', this.onMediaConnectionOpen);
    skyWayPeerEventEmitter.removeListener('SkyWayMediaConnectionClose', this.onMediaConnectionClose);
    skyWayPeerEventEmitter.removeListener('SkyWayMediaConnectionError', this.onMediaConnectionError);
    skyWayPeerEventEmitter.removeListener('SkyWayMediaConnectionError', this.onMediaConnectionError);
    skyWayPeerEventEmitter.removeListener('SkyWayRoomOpen', this.onRoomOpen);
    skyWayPeerEventEmitter.removeListener('SkyWayRoomPeerJoin', this.onRoomPeerJoin);
    skyWayPeerEventEmitter.removeListener('SkyWayRoomPeerLeave', this.onRoomPeerLeave);
    skyWayPeerEventEmitter.removeListener('SkyWayRoomLog', this.onRoomLog);
    skyWayPeerEventEmitter.removeListener('SkyWayRoomStream', this.onRoomStream);
    skyWayPeerEventEmitter.removeListener('SkyWayRoomRemoveStream', this.onRoomRemoveStream);
    skyWayPeerEventEmitter.removeListener('SkyWayRoomData', this.onRoomData);
    skyWayPeerEventEmitter.removeListener('SkyWayRoomClose', this.onRoomClose);
    skyWayPeerEventEmitter.removeListener('SkyWayRoomError', this.onRoomError);
  }

  connect() {
    if (this.disposed) {
      return;
    }

    SkyWayPeerManager.connect(this.peerId);
  }

  disconnect() {
    if (this.disposed) {
      return;
    }

    SkyWayPeerManager.disconnect(this.peerId);
  }

  listAllPeers(callback) {
    if (this.disposed) {
      return;
    }
    SkyWayPeerManager.listAllPeers(this.peerId, callback);
  }

  call(targetPeerId) {
    if (this.disposed) {
      return;
    }

    SkyWayPeerManager.call(this.peerId, targetPeerId);
  }

  answer() {
    if (this.disposed) {
      return;
    }

    SkyWayPeerManager.answer(this.peerId);
  }

  hangup() {
    if (this.disposed) {
      return;
    }

    SkyWayPeerManager.hangup(this.peerId);
  }

  joinRoom(roomId) {
    if (this.disposed) {
      return;
    }

    SkyWayPeerManager.joinRoom(this.peerId, roomId);
  }

  leaveRoom() {
    if (this.disposed) {
      return;
    }

    SkyWayPeerManager.leaveRoom(this.peerId);
  }

  switchCamera() {
    if (this.disposed) {
      return;
    }

    SkyWayPeerManager.switchCamera(this.peerId);
  }

  setLocalStreamStatus(status) {
    if (this.disposed) {
      return;
    }

    SkyWayPeerManager.setLocalStreamStatus(this.peerId, status);
  }

  onPeerOpen(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('peer-open'));
    }
  }

  onPeerCall(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('peer-call'));
    }
  }

  onPeerClose(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('peer-close'));
    }
  }

  onPeerDisconnected(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('peer-disconnected'));
    }
  }

  onPeerError(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('peer-error'));
    }
  }

  onMediaConnectionOpen(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('media-connection-open'));
    }
  }

  onMediaConnectionClose(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('media-connection-close'));
    }
  }

  onMediaConnectionError(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('media-connection-error'));
    }
  }

  onPeerStatusChange(payload) {
    if (payload.peer.id === this.peerId) {
      this._peerStatus = this.payload.status;
      this.dispatchEvent(new PeerEvent('peer-status-change'));
    }
  }

  onMediaConnectionStatusChange(payload) {
    if (payload.peer.id === this.peerId) {
      this._mediaConnectionStatus = this.payload.status;
      this.dispatchEvent(new PeerEvent('media-connection-status-change'));
    }
  }

  onRoomOpen(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('room-open'));
    }
  }

  onRoomPeerJoin(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('room-peer-join'));
    }
  }

  onRoomPeerLeave(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('room-peer-leave'));
    }
  }

  onRoomLog(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('room-log'));
    }
  }

  onRoomStream(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('room-stream'));
    }
  }

  onRoomRemoveStream(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('room-remove-stream'));
    }
  }

  onRoomData(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('room-data'));
    }
  }

  onRoomClose(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('room-close'));
    }
  }

  onRoomError(payload) {
    if (payload.peer.id === this.peerId) {
      this.dispatchEvent(new PeerEvent('room-error'));
    }
  }

}

Peer.PeerStatus = PeerStatus;
Peer.MediaConnectionStatus = MediaConnectionStatus;
