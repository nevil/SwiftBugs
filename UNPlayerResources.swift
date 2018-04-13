//
//  UNPlayerResources.swift
//  UNextSDK
//
//  Created by 阿部仁史 on 2015/04/03.
//  Copyright (c) 2015年 U-NEXT. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

struct UNLocalizedError: Error {

}

struct CommonError: Error {

}

struct UNPostPlayInfo {

}

struct UNConst {

}

struct UNSeekImageFetcher {

}

/**
 * UNPlayerResourcesプロトコル
 */

// Swift protocols can be declared to only apply to class types,
// so that any value conforming to the protocol must be a class object.
// This allows the class protocol to be used as the type of a weak var.
protocol UNPlayerResourcesDelegate: class {
    /// Retrieve the target layer for rendering the video.
    func playerWillSetTargetLayer(_ resources: UNPlayerResources) -> AVPlayerLayer?

    /// プレイヤーの読み込み状態が更新されたときに呼ばれる
    /// - seealso: `UNPlayerResources.bufferLevel`
    func playerDidChangeBufferLevel(_ resources: UNPlayerResources)

    /// プレイリストURLを再取得する準備をする時に呼ばれる
    /// Refresh completes when playerDidFinishPreparing() or player(:didFailWithError:) is received.
    func playerWillRefreshPlaylistURL(_ resources: UNPlayerResources)

    /// プレイヤーの準備が完了したときに呼ばれる
    /// - seealso: `UNPlayerResources.duration`
    func playerDidFinishPreparing(_ resources: UNPlayerResources)
    
    /// 現在の再生位置が変わったときに呼ばれる
    /// - seealso: `UNPlayerResources.duration`
    /// - seealso: `UNPlayerResources.currentTime`
    func playerDidUpdatePosition(_ resources: UNPlayerResources)

    /// 最後まで再生し終わったときに呼ばれる
    func playerDidCompletePlayback(_ resources: UNPlayerResources)
    
    /// 意図した動作が完了できなかった場合に呼ばれる
    /// - parameter error: エラーコード
    func player(_ resources: UNPlayerResources, didFailWithError error: UNLocalizedError)
    
    /// ポストプレイを表示するタイミングで呼ばれる
    /// シーク後の位置がポストプレイ表示位置(エンドロール開始位置)の場合も呼ばれる
    /// - parameter postPlay: ポストプレイの情報
    func player(_ resources: UNPlayerResources, didReachPostPlayTime postPlay: UNPostPlayInfo?)

    /// 再生ステータスが変わるタイミングで呼ばれる
    /// - parameter status: 再生ステータス（プレイ・ポーズ・シーク開始・最後まで再生）
    /// - seealso: `UNPlayerResources.duration`
    /// - seealso: `UNPlayerResources.currentTime`
    func player(_ resources: UNPlayerResources, didChangeStatus status: UNConst.Player.PlayStatus)

    /// Notifies the completion status of scene search file download.
    /// - parameter status: The result status of loading the file.
    /// - seealso: `UNPlayerResources.hasSceneSearchFile`
    func player(_ resources: UNPlayerResources, didFinishLoadingSceneSearchFile status: UNSeekImageFetcher.FetchingStatus)
}

/// A struct for storing a position in a video.
/// Uses millisecond accuracy.
/// Has convenienence functions for converting from/to seconds.
public struct UNPlaybackTime: Comparable {
    /// Will not return a negative value.
    private(set) var milliseconds: Int

    /// Convenience accessor.
    /// Will loose some precision in the returned timestamp.
    /// Will not return a negative value.
    var seconds: Int { return milliseconds / 1000 }

    var cmtime: CMTime {
        return CMTime(value: Int64(milliseconds) * Int64(NSEC_PER_MSEC), timescale: Int32(NSEC_PER_SEC))
    }

    /// Convenience constant for playback time 0
    static let zero = UNPlaybackTime(seconds: 0)

    /// Store timestamp in milliseconds
    /// Negative values are changed to 0.
    @inline(__always)
    init(milliseconds: Int) {
        if milliseconds < 0 {
            self.milliseconds = 0
        } else {
            self.milliseconds = milliseconds
        }
    }

    /// Convenience initializer for auto converting seconds to milliseconds
    /// Negative values are changed to 0.
    @inline(__always)
    init(seconds: Int) {
        self.init(milliseconds: seconds * 1000)
    }

    public static func +(lhs: UNPlaybackTime, rhs: UNPlaybackTime) -> UNPlaybackTime {
        return UNPlaybackTime(milliseconds: lhs.milliseconds + rhs.milliseconds)
    }

    public static func -(lhs: UNPlaybackTime, rhs: UNPlaybackTime) -> UNPlaybackTime {
        return UNPlaybackTime(milliseconds: lhs.milliseconds - rhs.milliseconds)
    }

    // MARK: UNPlaybackTime Comparable
    public static func < (lhs: UNPlaybackTime, rhs: UNPlaybackTime) -> Bool {
        return lhs.milliseconds < rhs.milliseconds
    }

    public static func == (lhs: UNPlaybackTime, rhs: UNPlaybackTime) -> Bool {
        return lhs.milliseconds == rhs.milliseconds
    }
}

/**
 * 再生インタフェース
 *
 * - Note: All functions that use AVPlayer should be called from the main queue.
 */
public final class UNPlayerResources: NSObject {
    /// 通常再生ファイル形式
    enum MoviePlayMode {
        case downloadedPlay
        case streamingPlay
    }

    enum BeaconKind {
        case signal
        case interruption
        case stop
    }

    enum PlayContentType {
        case movie(MovieData)
        case linear(UNBroadcastProgram)
        case live(UNLiveInfo)

        struct MovieData {
            let contentInfo: UNContentInfo
            let thumbnailSize: UNMoviePlayInfo.SceneSearchSize
            let playStatus: UNTrackingResources.PlayStatus
            let genre: UNGenre?
            let category: UNCategory?
            let featureInfo: UNFeatureInfo?

            init(contentInfo: UNContentInfo, thumbnailSize: UNMoviePlayInfo.SceneSearchSize, playStatus: UNTrackingResources.PlayStatus = .normalPlay, genre: UNGenre? = nil, category: UNCategory? = nil, featureInfo: UNFeatureInfo? = nil) {
                self.contentInfo = contentInfo
                self.thumbnailSize = thumbnailSize
                self.playStatus = playStatus
                self.genre = genre
                self.category = category
                self.featureInfo = featureInfo
            }
        }

        var trackingData: UNTrackingResources.PlayData {
            switch self {
            case .movie(let data):
                return UNTrackingResources.PlayData(
                    playStatus: data.playStatus,
                    screenMovingInfo: UNTrackingResources.ScreenMovingInfo(genre: (data.playStatus == .normalPlay ) ? data.genre : nil, category: (data.playStatus == .normalPlay ) ? data.category : nil, feature: (data.playStatus == .normalPlay ) ? data.featureInfo : nil)
                )
            default:
                return UNTrackingResources.PlayData(
                    playStatus: .normalPlay,
                    screenMovingInfo: UNTrackingResources.ScreenMovingInfo(genre: nil, category: nil, feature: nil)
                )
            }
        }
    }

    private struct RefreshPlaylistContext {
        let resumeTime: UNPlaybackTime?
        let shouldPause: Bool
    }

    private var contentType: PlayContentType?
    private var mediaItem: UNMediaItem?
    private var contentInfo: UNContentInfo?
    private var postPlayInfo: UNPostPlayInfo?

    private var imsFetcher: UNSeekImageFetcher?
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerTimeObserver: AnyObject?
    private var playBeaconTimer: Timer?

    private var needInitPlayer: Bool = true
    private var isSetPlay: Bool = false
    private var isSeeking: Bool = false
    private var isCallPostPlay: Bool = false
    private var isCompletedPlaying: Bool = false
    private var isRefreshingPlaylist: Bool = false
    private var refreshPlaylistContext: RefreshPlaylistContext?
    private var temporaryCurrentTime: UNPlaybackTime = UNPlaybackTime.zero

    private var movieMediaItem: UNMovieMediaItem? {
        return mediaItem as? UNMovieMediaItem
    }

    // MARK: Public properties

    /**
     * The delegate must be set before `setPlayer(contentInfo:genre:category:special:playStatus:completionHandler:)`
     * and remain set until `releasePlayer()` has been called.
     *
     * `releasePlayer()` is also setting the delegate to `nil`.
     */
    weak var delegate: UNPlayerResourcesDelegate?

    private(set) var bufferLevel: Int = 0

    /**
     * 収録時間を取得する
     */
    var duration: Int {
        guard let playerItem = self.player?.currentItem else {
            return -1
        }
        return CMTimeGetSecondsToInt(playerItem.duration)
    }

    /**
     * 再生時間を取得する
     *
     * 取得出来ない場合は-1を返す
     */
    var currentTime: UNPlaybackTime? {
        guard let playerItem = self.player?.currentItem, playerItem.status == .readyToPlay else {
            return nil
        }
        
        if isSeeking {
            // Return the fake current playing time only when AVPlayer is processing the seek
            return temporaryCurrentTime
        } else if isCompletedPlaying {
            // Return the content duration when play reaches end of content
            // Because with some content the metadata's duration is different from the real duration
            // So we prefer using the duration from metadata to match with the data in server.
            return UNPlaybackTime(seconds: movieMediaItem?.episodeInfo.duration ?? duration)
        } else {
            return UNPlaybackTime(seconds: CMTimeGetSecondsToInt(playerItem.currentTime()))
        }
    }

    var isMuted: Bool {
        get {
            return player?.isMuted ?? false
        }
        set {
            player?.isMuted = newValue
        }
    }
    
    /// 再生ファイル形式
    var moviePlayMode: MoviePlayMode {
        if let di = self.mediaItem as? UNDownloadMediaItem, di.downloadStatus == .finished {
            return .downloadedPlay
        } else {
            return .streamingPlay
        }
    }

    /// Is scene search file available?
    /// Must only be called after setupPlaying()'s completion handler has been called.
    var hasSceneSearchFile: Bool {
        guard let imsFetcher = self.imsFetcher else { return false }
        return [.ongoing, .completed].contains(imsFetcher.fetchingStatus)
    }

    // MARK: - Initialize

    override init() {
        super.init()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        registerNotifications()
    }

    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(UNPlayerResources.airPlayWirelessRouteActiveDidChange(_:)), name: NSNotification.Name.MPVolumeViewWirelessRouteActiveDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UNPlayerResources.newScreenDidConnect(_:)), name: NSNotification.Name.UIScreenDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UNPlayerResources.reachabilityDidChange(_:)), name: NSNotification.Name.reachabilityChanged, object: nil)

        UNMirroringResources.observeScreenCaptured(self, selector: #selector(UNPlayerResources.screenCapturedDidChange(_:)))
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.deinitPlayer()
    }
    
    // MARK: - UI-SDK IF
    
    /**
     * 指定したコンテンツを準備する
     *
     * - parameter contentInfo:  コンテンツ情報
     * - parameter thumbnailSize: Size of the scene search thumbnails
     * - playStatus TrackingPlayStatus: 再生状態　(普通、ポストプレイから再生、ホーム画面のつづきを見るから再生)
     * - seealso: `delegate`.
     */
    func setupPlaying(contentType: PlayContentType, completionHandler: @escaping (UNLocalizedError?) -> Void) {
        guard self.delegate != nil else {
            return completionHandler(PlayError.nullDelegate)
        }
        guard !UNMirroringResources.isMirroring else {
            return completionHandler(PlayError.mirroringNotSupported)
        }

        guard !UNMirroringResources.isCaptured else {
            return completionHandler(PlayError.screenRecordingNotAllowed)
        }

        self.temporaryCurrentTime = UNPlaybackTime.zero
        self.isStopped = false
        self.postPlayInfo = nil
        self.isCallPostPlay = false
        self.imsFetcher = nil // Release old imsFetcher
        self.contentType = contentType

        switch contentType {
        case .movie(let data):
            self.setupMoviePlaying(data: data, completionHandler: completionHandler)
        case .linear(let info):
            self.setupLinearPlaying(code: info.channelCode, completionHandler: completionHandler)
        case .live(let info):
            self.setupLivePlaying(info: info, completionHandler: completionHandler)
        }
    }

    private func setupMoviePlaying(data: PlayContentType.MovieData, completionHandler: @escaping (UNLocalizedError?) -> Void) {
        self.contentInfo = data.contentInfo
        if let item = UNext.downloadResources.getItem(for: data.contentInfo.code), item.downloadStatus == .finished {
            /* Download再生 */
            item.delegate = self
            self.mediaItem = item
            self.setPlayerForPlaying(item, completionHandler: completionHandler)
        } else {
            /* Streaming再生 */
            UNPlaylistUtility.getPlaylistInfo(for: .normalPlay, playMode: UNSharedSettings.playModeSetting, episodeInfo: data.contentInfo.episodeInfo) { (response) in
                switch response {
                case let .success(res):

                    let item = UNMovieMediaItem(contentInfo: data.contentInfo, playlistInfo: res.playlistInfo, profile: res.contentProfile)
                    item.delegate = self
                    self.mediaItem = item

                    if let url = item.moviePlaylistInfo.playInfo.sceneSearchURLs[data.thumbnailSize] {

                        let cachePaths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory,
                                                                             FileManager.SearchPathDomainMask.userDomainMask,
                                                                             true)
                        let cachePath = (cachePaths[0] as NSString).appendingPathComponent("imscache")
                        UNCommonUtility.createDirectory(cachePath)
                        self.imsFetcher = UNSeekImageFetcher(url: url, cacheFolder: cachePath)
                    }
                    self.setPlayerForPlaying(item, completionHandler: completionHandler)

                case let .failure(err):
                    DispatchQueueSafe.main.sync {
                        completionHandler(err)
                    }
                    self.sendErrorLog(err)
                }
            }
        }
    }

    private func setupLinearPlaying(code: UNChannelCode, completionHandler: @escaping (UNLocalizedError?) -> Void) {
        UNPlaylistUtility.getPlaylistInfoForLinear(channelCode: code.rawValue) { (response) in
            switch response {
            case .success(let res):
                guard let contentProfile = res.playInfo.profile(for: .normalPlay) else {
                    DispatchQueueSafe.main.sync {
                        completionHandler(PlayError.unknown)
                    }
                    return
                }
                let item = UNMediaItem(code: code.rawValue, playlistInfo: res, contentProfile: contentProfile)
                item.delegate = self
                self.mediaItem = item
                self.setPlayerForPlaying(item, completionHandler: completionHandler)
            case .failure(let err):
                DispatchQueueSafe.main.sync {
                    completionHandler(err)
                }
                self.sendErrorLog(err)
            }
        }
    }

    private func setupLivePlaying(info: UNLiveInfo, completionHandler: @escaping (UNLocalizedError?) -> Void) {
        UNPlaylistUtility.getPlaylistInfoForLive(code: info.code) { (response) in
            switch response {
            case .success(let res):
                guard let contentProfile = res.playInfo.profile(for: .normalPlay) else {
                    DispatchQueueSafe.main.sync {
                        completionHandler(PlayError.unknown)
                    }
                    return
                }
                let item = UNMediaItem(code: info.code, playlistInfo: res, contentProfile: contentProfile)
                item.delegate = self
                self.mediaItem = item
                self.setPlayerForPlaying(item, completionHandler: completionHandler)
            case .failure(let err):
                DispatchQueueSafe.main.sync {
                    completionHandler(err)
                }
                self.sendErrorLog(err)
            }
        }
    }

    /**
     * プレイヤーを解放する
     */
    func releasePlayer() {
        self.deinitPlayer()
        self.delegate = nil
    }
    
    // MARK: Event
    
    /// コンテンツを再生する
    /// - parameter startTime: 再生開始時間(optional)
    /// - parameter needPause: trueの場合、再生は自動開始しない(一時停止状態のまま)
    func startPlay(from time: UNPlaybackTime? = nil, needPause: Bool = false, completionHandler: @escaping (Bool) -> Void) {
        guard let player = self.player, nil != player.currentItem, !isPlaying else {
            return completionHandler(false)
        }
        self.isStopped = false
        player.allowsExternalPlayback = true
        let currentPosition: UNPlaybackTime = {
            return time ?? self.movieMediaItem?.playingResumePoint ?? UNPlaybackTime.zero
        }()

        self.seek(to: currentPosition) { _ in
            if !needPause {
                player.play()
            }
            completionHandler(true)
            self.sendStartPlaybackLog()
        }
    }

    /// 再生中のコンテンツを一時停止する
    @discardableResult
    func pausePlay() -> Bool {
        guard let player = self.player, let currentTime = self.currentTime, player.currentItem != nil, isPlaying else {
            return false
        }
        player.pause()
        temporaryCurrentTime = currentTime
        sendBeaconAndUpdateResumePointIfNeeded(beaconKind: .interruption, mode: moviePlayMode)
        return true
    }

    /// 一時停止中のコンテンツを再生再開する
    @discardableResult
    func resumePlay() -> Bool {
        guard let player = self.player,
            player.currentItem != nil, !isPlaying else {
            return false
        }

        player.play()
        self.informPositionUpdated()

        return true
    }

    /// もう一度master playlistを取得してから,　コンテンツを再生します。
    @discardableResult
    func restartPlay(_ isMuted: Bool) -> Bool {
        func handleSetupError(_ error: UNLocalizedError?) {
            guard error == nil else {
                informPlayerError(error!)
                return
            }
            self.startPlay(completionHandler: { (res) in
                guard res == true else {
                    self.informPlayerError(PlayError.unknown)
                    return
                }
            })
        }

        return refreshPlaylistURL(shouldPause: true)
    }

    /// 再生中のコンテンツを停止する
    /// コンテンツ切替時にも呼ぶ
    @discardableResult
    func stopPlay() -> Bool {
        guard let player = self.player, player.currentItem != nil, !self.isStopped else {
            UNLog("player nil")
            return false
        }
        // Stop sending the signal beacon before removing the player to avoid reading of currentTime.
        // currentTime will be nil after the player is removed.
        self.removeSignalBeaconTimer()

        self.isStopped = true
        player.pause()
        self.temporaryCurrentTime = self.currentTime ?? UNPlaybackTime.zero
        player.allowsExternalPlayback = false
        self.removePlayer()
        self.mediaItem?.stopPlayback()

        self.sendEndPlaybackLog()
        sendBeaconAndUpdateResumePointIfNeeded(beaconKind: .stop, mode: moviePlayMode)
        isCompletedPlaying = false

        return true
    }

    /// シーク処理
    func seek(to time: UNPlaybackTime, completionHandler: @escaping (Bool) -> Void) {
        guard let player = self.player,
            let playerItem = player.currentItem, playerItem.status == .readyToPlay else {
                return completionHandler(false)
        }

        playerItem.cancelPendingSeeks()
        self.isSeeking = true
        self.isCompletedPlaying = false

        // Seeking to a position after the end of the content can cause playerItemDidPlayToEndNotification to not
        // be delivered. Additionally the duration value is not always perfectly accurate as it can return a slightly
        // larger value than the actual playback duration.
        // To solve this we adjust seek positions close to end to have a 1 second margin.
        let endOfContent = UNPlaybackTime(seconds: duration - 1)
        let adjustedTargetTime = min(time, endOfContent)
        let targetTime = adjustedTargetTime.cmtime

        // Remember the seeking time destination, returned during seek as current play time in self.currentTime
        self.temporaryCurrentTime = adjustedTargetTime

        // ステータス更新
        self.informPlayStatusChanged(UNConst.Player.PlayStatus.seeking)
        player.seek(to: targetTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { finished in
            self.isCallPostPlay = false
            self.isSeeking = false
            let playStatus: UNConst.Player.PlayStatus = self.isPlaying ? .play : .pause
            self.informPlayStatusChanged(playStatus)
            completionHandler(finished)
        })
    }

    /**
     * 再生モード（吹替・字幕）を変える
     *
     * モード変更が正常に行われた場合、UNPlayerResourcesDelegate#playerDidFinishPreparing()が呼ばれる
     *
     * - parameter playMode: 再生モード（吹替・字幕）
     */
    func changePlayMode(_ playMode: UNPlayMode, completionHandler: @escaping (UNLocalizedError?) -> Void) {
        guard UNSharedSettings.playModeSetting != playMode else {
            return completionHandler(nil)
        }
        guard let ci = self.contentInfo else {
            completionHandler(CommonError.noContent)
            self.sendErrorLog(CommonError.noContent)
            return
        }
        
        self.stopPlay()
        self.removePlayer()
        let beforeInfo = UNSharedSettings.playModeSetting
        UNSharedSettings.playModeSetting = playMode
        UNPlaylistUtility.getPlaylistInfo(for: .normalPlay, playMode: playMode, episodeInfo: ci.episodeInfo) { (response) in
            switch response {
            case let .success(res):
                let item = UNMovieMediaItem(contentInfo: ci, playlistInfo: res.playlistInfo, profile: res.contentProfile)
                item.delegate = self
                self.mediaItem = item

                self.setPlayerForPlaying(item, completionHandler: completionHandler)

            case let .failure(err):
                UNSharedSettings.playModeSetting = beforeInfo
                DispatchQueueSafe.main.sync {
                    completionHandler(err)
                }
                self.sendErrorLog(err)
            }
        }
    }

    typealias TimestampedThumbnail = (image: UIImage?, exactTime: UNPlaybackTime)

    /// Receive thumbnail and exact time for the thumbnail
    /// The exact time can be used to adjust the seek destination to the exact
    /// location where the thumbnail was captured.
    ///
    /// - parameter time: Start point used to search for the thumbnail.
    /// - result: A pair containing the thumbnail and the exact thumbnail capture time.
    func thumbnail(at time: UNPlaybackTime) -> TimestampedThumbnail? {
        guard let imsFetcher = self.imsFetcher,
            let pts = imsFetcher.presentationTime(at: UInt(time.milliseconds)) else {

            return nil
        }

        return (image: imsFetcher.image(at: pts), exactTime: UNPlaybackTime(milliseconds: Int(pts)))
    }

    /// ポストプレイ要求
    func requestPostPlay(_ completionHandler: @escaping (UNResponse<UNPostPlayInfo, UNLocalizedError>) -> Void) {
        if let nextContent = nextDownloadContent {
            // Next video is downloaded
            self.postPlayInfo = UNPostPlayInfo(info: nextContent)
        }
        
        if let postPlay = self.postPlayInfo {
            // If postplay information's received before, send that information
            return completionHandler(.success(postPlay))
        }
        
        guard let currentContent = self.contentInfo,
            nil != player?.currentItem else {
                return completionHandler(.failure(PlayError.unknown))
        }
        
        let parameters: JSONDictionary = [
            "episode_code": currentContent.code.rawValue,
            "film_rating_code": UNSharedSettings.filmRatingCode
        ]
        UNApiClientManager.sharedInstance.postDataToServer(UNConst.Api.Tag.getPostPlayInfo, data: parameters) { (response) in
            switch response {
            case let .success(res):
                let postPlay = UNPostPlayInfo(json: res.data)
                self.postPlayInfo = postPlay
                DispatchQueueSafe.main.sync {
                    completionHandler(.success(postPlay))
                }
                
            case let .failure(error):
                DispatchQueueSafe.main.sync {
                    completionHandler(.failure(error))
                }
            }
        }
    }
    
    // MARK: Check
    
    /**
     * 再生中かどうか
     *
     * 再生中ならtrueを返す
     */
    var isPlaying: Bool {
        guard let player = self.player else {
            return false
        }
        return player.rate != 0
    }
    
    /**
     * 停止処理済みかどうか
     *
     * 停止処理済みならtrueを返す
     */
    var isStopped: Bool = false

    /// Returns true if playback is paused
    /// Returns false if no playback or if stop has been called.
    var isPaused: Bool {
        guard let player = self.player else { return false }
        return player.rate == 0 && !isStopped
    }

    // MARK: - Observer
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let kp = keyPath else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch (kp, context) {
        case (#keyPath(AVPlayer.rate), UNConst.Player.PlayerObserverContext?):
            guard !self.isCompletedPlaying,
                let newValue = change?[.newKey] as? Int,
                let oldValue = change?[.oldKey] as? Int,
                newValue != oldValue else {
                    break
            }
            let playStatus: UNConst.Player.PlayStatus = newValue == 0 ? .pause : .play
            self.informPlayStatusChanged(playStatus)

        case (#keyPath(AVPlayer.isExternalPlaybackActive), UNConst.Player.PlayerObserverContext?):
            // We check every time the state of isExternalPlaybackActive is.
            if UNMirroringResources.isMirroring {
                informPlayerError(PlayError.mirroringNotSupported)
                return
            } else if UNMirroringResources.isCaptured {
                informPlayerError(PlayError.screenRecordingNotAllowed)
                return
            }

        case (#keyPath(AVPlayerItem.isPlaybackBufferEmpty), UNConst.Player.PlayerItemObserverContext?):
            if self.moviePlayMode == .streamingPlay {
                UNLog("PlayerItemEmptyBufferKey")
                if UNCommonUtility.isOffline {
                    self.informPlayerError(PlayError.connectionFailed)
                }
            }
        case (#keyPath(AVPlayerItem.status), UNConst.Player.PlayerItemObserverContext?):
            if let c = change, let value = c[.newKey] as? Int, let status = AVPlayerStatus(rawValue: value), self.playerItem != nil {
                switch status {
                case .readyToPlay:
                    if self.isSetPlay {
                        self.isSetPlay = false
                        
                        self.setPlayerTimeObserver()
                        self.bufferLevel = 100
                        
                        self.informBufferLevelChanged()

                        // If this is a refresh case we should resume playback from the stored position.
                        if self.isRefreshingPlaylist {
                            self.startPlay(from: self.refreshPlaylistContext?.resumeTime, needPause: self.refreshPlaylistContext?.shouldPause ?? false) { [weak self] (completed) in
                                guard let `self` = self else { return }
                                self.isRefreshingPlaylist = false
                                self.refreshPlaylistContext = nil
                                self.informFinishedPreparing()
                            }
                        } else {
                            self.informFinishedPreparing()
                        }
                    }

                case .failed:
                    self.informPlayerError(PlayError.unknown)
                    
                case .unknown:
                    break
                }
            }
        case (#keyPath(AVPlayerItem.loadedTimeRanges), UNConst.Player.PlayerItemObserverContext?):
            guard let playerItem = self.playerItem, self.bufferLevel < 100 else {
                return
            }
            
            let timeRanges = playerItem.loadedTimeRanges
            if timeRanges.count > 0 {
                let value = timeRanges[0] as NSValue
                let timeRange = value.timeRangeValue
                self.bufferLevel = Int(CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration)) * 10
                if case 0 ... 100 = self.bufferLevel {
                    UNLog("percent: \(self.bufferLevel)")
                    self.informBufferLevelChanged()
                }
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: - Private
    
    private func initPlayer() {
        guard let player = self.player else {
            return
        }
        
        self.addPlayerObserver()
        
        player.allowsExternalPlayback = true
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
    }
    
    private func deinitPlayer() {
        self.imsFetcher = nil

        // 再生完了
        self.player?.allowsExternalPlayback = false
        self.mediaItem?.stopPlayback()
        
        // 破棄
        self.removePlayer()

        self.mediaItem?.delegate = nil
        self.mediaItem = nil
        self.contentInfo = nil
        self.postPlayInfo = nil
        
        self.isSetPlay = false
        self.isSeeking = false
        self.isCallPostPlay = false
        self.bufferLevel = 0
        self.temporaryCurrentTime = UNPlaybackTime.zero
        self.isStopped = false
        self.isRefreshingPlaylist = false
        self.refreshPlaylistContext = nil
    }

    private func attachPlayerToLayer() throws {
        guard let player = self.player, let layer = self.delegate?.playerWillSetTargetLayer(self) else {
            throw PlayError.noAVPlayerLayer
        }

        layer.player = player
    }

    private func setPlayerForConfig() throws {
        if self.needInitPlayer {
            self.needInitPlayer = false
            self.initPlayer()
        }

        self.isSetPlay = true
        self.bufferLevel = 0

        try self.attachPlayerToLayer()
    }

    /// - NOTE: setPlayerForPlaying() does get passed the application's completionHandler.
    ///         This means this function must call the completionHandler on the main queue.
    ///
    private func setPlayerForPlaying(_ item: UNMediaItem, completionHandler: @escaping (UNLocalizedError?) -> Void) {
        item.checkLicenseAndCreateItem { (response) in
            switch response {
            case let .success(res):
                // Make sure to update the player on the main thread
                DispatchQueueSafe.main.sync {
                    if self.player != nil || self.playerItem != nil {
                        self.removePlayer()
                    }

                    self.playerItem = res

                    self.contentType.map {
                        switch $0 {
                        case .live, .linear:
                            UNPlaylistUtility.setPreferredPeakBitrate(on: res)
                        case .movie:
                            break
                        }
                    }

                    self.playerItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
                    self.addPlayerItemObservers()

                    // Per best practices information available at the below URL, the best approach is to
                    // create a player without a player item, set the video layer and later use
                    // replaceCurrentItemWithPlayerItem() to initiate the data path.
                    // The reason is that if AVPlayer is passed a player item before the video layer is
                    // set the player starts audio only playback. When the layer is set the player reinitializes
                    // for audio/video playback. This is less efficient.
                    // https://developer.apple.com/videos/play/wwdc2016/503/
                    self.player = AVPlayer()
                    do {
                        try self.setPlayerForConfig()
                        // The AVPlayer is added to an AVPlayerLayer inside setPlayerForConfig()
                        // Only set the player item to the player after this. See comment above.
                        self.player?.replaceCurrentItem(with: self.playerItem)
                        self.setSignalBeaconTimer()

                        self.imsFetcher?.startFetching { [weak self] fetchCompleted in
                            UNLog("Fetching completion called with result \(fetchCompleted)")
                            guard let `self` = self, let imsFetcher = self.imsFetcher else { return }

                            DispatchQueueSafe.main.sync {
                                self.delegate?.player(self, didFinishLoadingSceneSearchFile: imsFetcher.fetchingStatus)
                            }
                        }

                        completionHandler(nil)
                    } catch let error as PlayError {
                        completionHandler(error)
                    } catch {
                        // Unknown error
                        completionHandler(PlayError.unknown)
                    }
                }

            case let .failure(err):
                DispatchQueueSafe.main.sync {
                    completionHandler(err)
                }
                self.sendErrorLog(err)
            }
        }
    }

    private func removePlayer() {
        guard self.playerItem != nil || self.player != nil else {
            return
        }

        self.removePlayerItemObservers()
        self.playerItem?.cancelPendingSeeks()
        self.playerItem = nil

        self.removePlayerObserver()
        self.removePlayerTimeObserver()
        self.player?.pause()
        self.player?.cancelPendingPrerolls()
        self.player?.replaceCurrentItem(with: nil)
        self.player = nil

        self.needInitPlayer = true
    }
    
    private func addPlayerObserver() {
        self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.new, .old], context: UNConst.Player.PlayerObserverContext)
        self.player?.addObserver(self, forKeyPath: #keyPath(AVPlayer.isExternalPlaybackActive), options: [.new, .old], context: UNConst.Player.PlayerObserverContext)
    }
    
    private func removePlayerObserver() {
        self.player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: UNConst.Player.PlayerObserverContext)
        self.player?.removeObserver(self, forKeyPath: #keyPath(AVPlayer.isExternalPlaybackActive), context: UNConst.Player.PlayerObserverContext)
    }
    
    private func addPlayerItemObservers() {
        self.playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.new], context: UNConst.Player.PlayerItemObserverContext)
        self.playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: UNConst.Player.PlayerItemObserverContext)
        self.playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: [.new, .initial], context: UNConst.Player.PlayerItemObserverContext)

        self.addPlayerItemNotifications()
    }
    
    private func removePlayerItemObservers() {
        func safeRemovePlayerItemObserver(forKeyPath keyPath: String) {
            do {
                try UNTryCatch.try {
                    self.playerItem?.removeObserver(self, forKeyPath: keyPath, context: UNConst.Player.PlayerItemObserverContext)
                }
            } catch let error as NSError {
                UNLog("exception: \(error.localizedDescription)")
            }
        }

        safeRemovePlayerItemObserver(forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
        safeRemovePlayerItemObserver(forKeyPath: #keyPath(AVPlayerItem.status))
        safeRemovePlayerItemObserver(forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))

        self.removePlayerItemNotifications()
    }

    private func setPlayerTimeObserver() {
        guard let player = self.player, nil != player.currentItem else {
            return
        }
        
        if self.playerTimeObserver == nil {
            self.playerTimeObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(300, 600),
                queue: DispatchQueue.main,
                using: {[unowned self] _ in
                    if self.isPlaying && !self.isSeeking {
                        self.informPositionUpdated()
                    }
                }) as AnyObject?
        }
    }

    private func removePlayerTimeObserver() {
        guard let playerTimeObserver = self.playerTimeObserver else {
            return
        }
        self.player?.removeTimeObserver(playerTimeObserver)
        self.playerTimeObserver = nil
    }
    
    /// 次話はダウンロード一覧に入っているコンテンツなら返す
    private var nextDownloadContent: UNDownloadableContentInfo? {
        guard let currentItem = movieMediaItem else {
            return nil
        }
        if let item = UNext.downloadResources.getItem(for: currentItem.titleInfo.code, episodeNo: currentItem.episodeInfo.no + 1) {
            return item.contentInfo
        } else {
            return nil
        }
    }

    @discardableResult
    private func refreshPlaylistURL(shouldPause: Bool) -> Bool {
        guard let contentType = contentType else { return false }

        // Capture the current state so that we can resume if needed.
        // stopPlay() below removes the current player so we have to read the values here.
        isRefreshingPlaylist = true
        let savedTime = currentTime

        DispatchQueueSafe.main.sync {
            self.delegate?.playerWillRefreshPlaylistURL(self)
        }

        stopPlay()

        let localSetupPlaying: (_: (@escaping (UNLocalizedError?) -> Void)) -> Void = { [weak self] (completionHandler) in
            guard let `self` = self else { return }

            switch contentType {
            case .linear(let program):
                self.refreshPlaylistContext = RefreshPlaylistContext(resumeTime: nil, shouldPause: shouldPause)
                self.setupLinearPlaying(code: program.channelCode, completionHandler: completionHandler)
            case .live(let info):
                self.refreshPlaylistContext = RefreshPlaylistContext(resumeTime: nil, shouldPause: shouldPause)
                self.setupLivePlaying(info: info, completionHandler: completionHandler)
            case .movie(let data):
                self.refreshPlaylistContext = RefreshPlaylistContext(resumeTime: savedTime, shouldPause: shouldPause)
                self.setupMoviePlaying(data: data, completionHandler: completionHandler)
            }
        }

        // When resuming playback from a locked device the first attempt often fails as network is not yet fully available.
        // To handle this case we retry after a short delay of 1 seconds.
        var retriesRemaining = 2

        let handleSetupError: (UNLocalizedError?) -> Void = { [weak self] (error) in
            guard let `self` = self else { return }

            guard error == nil else {
                DispatchQueueSafe.main.sync {
                    guard retriesRemaining > 0 else {
                        self.informPlayerError(error!)
                        return
                    }

                    retriesRemaining -= 1

                    // Retry after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        localSetupPlaying(handleSetupError)
                    }
                }
                return
            }
        }

        localSetupPlaying(handleSetupError)
        return true
    }

    
    // MARK: Beacon
    
    /// 再生ビーコンを送信するタイマー
    private func setSignalBeaconTimer() {
        removeSignalBeaconTimer()
        guard let item = self.mediaItem, item.playlistInfo.beaconSpan > 0 else {
            return
        }
        let beaconTimeInterval = TimeInterval(item.playlistInfo.beaconSpan)
        DispatchQueueSafe.main.sync {
            self.playBeaconTimer = Timer.scheduledTimer(timeInterval: beaconTimeInterval, target: self, selector:
                #selector(UNPlayerResources.signalBeaconTimerHandler), userInfo: nil, repeats: true)
        }
    }
    
    private func removeSignalBeaconTimer() {
        if let timer = self.playBeaconTimer, timer.isValid {
            timer.invalidate()
        }
        playBeaconTimer = nil
    }

    @objc private func signalBeaconTimerHandler() {
        sendBeaconAndUpdateResumePointIfNeeded(beaconKind: .signal, mode: moviePlayMode)
    }

    private func sendBeaconAndUpdateResumePointIfNeeded(beaconKind: BeaconKind, mode: MoviePlayMode) {
        guard let type = self.contentType else { return }
        switch type {
        case .movie:
            self.updateResumePointAndSendBeaconForMovie(beaconKind, mode: mode)
        case .linear:
            // No need to update resume point
            self.sendBeaconForLinear(beaconKind)
        case .live:
            // No need to update resume point
            self.sendBeaconForLive(beaconKind)
        }
    }

    private func sendBeaconForLinear(_ beaconKind: BeaconKind) {
        guard let item = mediaItem else { return }
        switch beaconKind {
        case .signal:
            UNApiClientManager.sharedInstance.sendSignalBeacon(.linear(playToken: item.playlistInfo.playToken)) { (error) in
                self.handleBeaconError(error)
            }
            self.handleBeaconError(BeaconError.needRefreshPlaylistURL)
        case .interruption:
            UNApiClientManager.sharedInstance.sendInterruptionBeacon(.linear)
        case .stop:
            UNApiClientManager.sharedInstance.sendStopBeacon(.linear(playToken: item.playlistInfo.playToken))
        }
    }

    private func sendBeaconForLive(_ beaconKind: BeaconKind) {
        guard let item = mediaItem else { return }
        switch beaconKind {
        case .signal:
            UNApiClientManager.sharedInstance.sendSignalBeacon(.live(playToken: item.playlistInfo.playToken)) { (error) in
                self.handleBeaconError(error)
            }
        case .interruption:
            UNApiClientManager.sharedInstance.sendInterruptionBeacon(.live)
        case .stop:
            UNApiClientManager.sharedInstance.sendStopBeacon(.live(playToken: item.playlistInfo.playToken))
        }
    }

    private func handleBeaconError(_ error: BeaconError?) {
        guard let error = error else {
            return
        }

        switch error {
        case .needRefreshPlaylistURL:
            refreshPlaylistURL(shouldPause: false)

        default:
            break
        }
    }

    private func updateResumePointAndSendBeaconForMovie(_ beaconKind: BeaconKind, mode: MoviePlayMode) {
        guard let item = movieMediaItem else { return }
        let resumePoint: UNPlaybackTime
        // When sending the stop beacon we don't have a player item so we need to use the saved time
        if beaconKind == .stop {
            let duration = UNPlaybackTime(seconds: item.episodeInfo.duration)
            resumePoint = self.temporaryCurrentTime > duration ? duration : self.temporaryCurrentTime
        } else {
            resumePoint = currentTime ?? UNPlaybackTime.zero
        }
        // レジュームポイントを更新
        updateResumePointForItem(item, time: resumePoint)

#if !DISABLE_CAST_SDK
        guard UNext.chromecastResources.status != .connecting else {
            return
        }
#endif
        switch mode {
        case .streamingPlay:
            var fileCode: UNMoviePlayInfo.FileCode {
                return item.moviePlaylistInfo.playInfo.code
            }
            switch beaconKind {
            case .signal:
                UNApiClientManager.sharedInstance.sendSignalBeacon(.movie(playToken: item.playlistInfo.playToken, fileCode: fileCode, playTime: resumePoint)) { (error) in
                    self.handleBeaconError(error)
                }
            case .interruption:
                UNApiClientManager.sharedInstance.sendInterruptionBeacon(.movie(playToken: item.playlistInfo.playToken, fileCode: fileCode, playTime: resumePoint))

            case .stop:
                UNApiClientManager.sharedInstance.sendStopBeacon(.movie(playToken: item.playlistInfo.playToken, fileCode: fileCode, playTime: resumePoint, completedView: isCompletedPlaying))
            }
        case .downloadedPlay:
            if beaconKind == .stop {
                let info = UNApiClientManager.SendResumePointInfo(episodeCode: item.episodeInfo.code, resumePoint: resumePoint.seconds, isCompletedView: isCompletedPlaying, viewedDate: Date(), playMode: .downloadedPlay)
                UNApiClientManager.sharedInstance.sendResumePoint(info: info) { (error) in
                    guard let item = item as? UNDownloadMediaItem else { return }
                    item.updateNeedsToSendResumePoint(error != nil)
                }
            }
        }
    }

    // レジュームポイントを保存
    private func updateResumePointForItem(_ item: UNMovieMediaItem, time: UNPlaybackTime) {
        // エンドロールを過ぎた場合、0を保存する
        let point = item.episodeInfo.endrollPosition > UNPlaybackTime.zero && time > item.episodeInfo.endrollPosition ? UNPlaybackTime.zero : time
        item.updatePlayingResumePoint(point, isCompletedView: isCompletedPlaying)

        if !(item is UNDownloadMediaItem) {
            // Make sure to also update the resume point for any ongoing downloads for the same content code.
            // The UNMediaItem is not shared
            UNext.downloadResources.updateResumePoint(point, for: item.episodeInfo.code, isCompletedView: isCompletedPlaying)
        }

        UNNotification.ContentResumePointUpdated.post(episodeCode: item.episodeInfo.code, resumePoint: point)
    }
    
    // MARK: Log

    private var playbackLog: UNTrackingResources.PlaybackLog? {
        guard let contentType = self.contentType else { return nil }
        switch contentType {
        case .movie:
            guard let mediaItem = self.movieMediaItem else { return nil }
            return .movie(mediaItem: mediaItem, trackingData: contentType.trackingData)
        case .linear:
            guard let mediaItem = self.mediaItem else { return nil }
            return .linear(mediaItem: mediaItem)
        case .live:
            guard let mediaItem = self.mediaItem else { return nil }
            return .live(mediaItem: mediaItem)
        }
    }
    
    private func sendStartPlaybackLog() {
        guard let log = playbackLog else { return }
        UNext.trackingResources.startPlayback(log: log)
    }
    
    private func sendEndPlaybackLog() {
        guard let log = playbackLog else { return }
        UNext.trackingResources.endPlayback(log: log)
    }
    
    private func sendErrorLog(_ error: UNLocalizedError) {
        UNext.trackingResources.error(error, contentInfo: self.contentInfo, mediaItem: self.movieMediaItem)
    }
    
    // MARK: UNPlayerResourcesDelegate Private
    
    private func informBufferLevelChanged() {
        DispatchQueueSafe.main.sync {
            self.delegate?.playerDidChangeBufferLevel(self)
        }
    }

    private func informFinishedPreparing() {
        guard let player = self.player, nil != player.currentItem else {
            return
        }
        DispatchQueueSafe.main.sync {
            self.delegate?.playerDidFinishPreparing(self)
        }
    }

    private func informPositionUpdated() {
        guard let player = self.player, nil != player.currentItem else {
            return
        }
        DispatchQueueSafe.main.sync {
            self.delegate?.playerDidUpdatePosition(self)
        }
        guard let episode = movieMediaItem?.episodeInfo else {
            return
        }
        // Inform post play reached (if needed)
        if !isCallPostPlay && !isSeeking && episode.endrollPosition > UNPlaybackTime.zero, let ct = currentTime, ct >= episode.endrollPosition {
            isCallPostPlay = true
            informPostPlayReached()
        }
    }
    
    private func informPlaybackCompleted() {
        if !isCallPostPlay {
            isCallPostPlay = true
            informPostPlayReached()
        }
        DispatchQueueSafe.main.sync {
            self.delegate?.playerDidCompletePlayback(self)
        }
    }

    fileprivate func informPlayerError(_ error: UNLocalizedError) {
        self.sendErrorLog(error)
        self.stopPlay()
        DispatchQueueSafe.main.sync {
            self.delegate?.player(self, didFailWithError: error)
        }
    }

    private func informPlayStatusChanged(_ playStatus: UNConst.Player.PlayStatus) {
        DispatchQueueSafe.main.sync {
            self.delegate?.player(self, didChangeStatus: playStatus)
        }
    }

    private func informPostPlayReached() {
        if let nextContent = nextDownloadContent {
            // Next video is downloaded
            self.postPlayInfo = UNPostPlayInfo(info: nextContent)
        }
        DispatchQueueSafe.main.sync {
            self.delegate?.player(self, didReachPostPlayTime: self.postPlayInfo)
        }
    }

    // MARK: - Notifications
    

    /// AirPlay接続通知
    @objc private func airPlayWirelessRouteActiveDidChange(_ notification: Notification) {
        if UNMirroringResources.isMirroring {
            informPlayerError(PlayError.mirroringNotSupported)
            return
        } else if UNMirroringResources.isCaptured {
            informPlayerError(PlayError.screenRecordingNotAllowed)
            return
        }

        if UNext.trackingResources.isStartPlayback {
            self.sendEndPlaybackLog()
        }
        self.sendStartPlaybackLog()
    }

    @objc private func screenCapturedDidChange(_ notification: Notification) {
        if UNMirroringResources.isCaptured {
            informPlayerError(PlayError.screenRecordingNotAllowed)
        }
    }

    @objc private func newScreenDidConnect(_ notification: Notification) {
        if UNMirroringResources.isMirroring {
            informPlayerError(PlayError.mirroringNotSupported)
        }
    }

    @objc private func reachabilityDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let playerItem = self?.playerItem else { return }

            self?.contentType.map {
                switch $0 {
                case .live, .linear:
                    UNLog("reachabilityDidChange, updating preferredPeakBitrate")
                    UNPlaylistUtility.setPreferredPeakBitrate(on: playerItem)
                case .movie:
                    break
                }
            }
        }
    }
    
    private func addPlayerItemNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(UNPlayerResources.playerItemDidPlayToEndNotification), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(UNPlayerResources.playerItemFailedToPlayToEndNotification), name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: self.playerItem)
        #if DEBUG
        NotificationCenter.default.addObserver(self, selector: #selector(UNPlayerResources.playerItemNewAccessLogEntry(_:)), name: NSNotification.Name.AVPlayerItemNewAccessLogEntry, object: self.playerItem)
        #endif
        NotificationCenter.default.addObserver(self, selector: #selector(UNPlayerResources.playerItemRegisteredErrorEntryNotification(_:)), name: NSNotification.Name.AVPlayerItemNewErrorLogEntry, object: self.playerItem)
    }
    
    private func removePlayerItemNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: self.playerItem)
        #if DEBUG
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemNewAccessLogEntry, object: self.playerItem)
        #endif
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemNewErrorLogEntry, object: self.playerItem)
    }
    
    /**
     * 再生終了時の通知
     */
    @objc private func playerItemDidPlayToEndNotification() {
        self.isCompletedPlaying = true

        // ステータス更新
        self.informPlayStatusChanged(UNConst.Player.PlayStatus.end)
        self.informPlaybackCompleted()
    }

    /**
     * 再生失敗時の通知
     */
    @objc private func playerItemFailedToPlayToEndNotification() {
        self.printLogOfPlayerItem(self.playerItem)
        self.informPlayerError(UNMirroringResources.isExternalPlayback ? PlayError.airplayForcedEnded : PlayError.unknown)
    }

    #if DEBUG
    @objc private func playerItemNewAccessLogEntry(_ notification: Notification) {
        guard let playerItem = self.playerItem else { return }
        guard let accessLog = playerItem.accessLog() else { return }

        if #available(iOS 10.0, *) {
            for (i, e) in accessLog.events.enumerated() {
                UNLog("accessLog event \(i) -> indicated: \(e.indicatedBitrate) average: \(e.averageAudioBitrate + e.averageVideoBitrate)")
            }
        }
    }
    #endif

    @objc private func playerItemRegisteredErrorEntryNotification(_ notification: Notification) {
        // Taken from DownloadableAgent Sample app
        // <quote>
        // errorStatusCode=-1004 means that client wasn't able to connect to the server
        // errorStatusCode=-12880 means that it wasn't possible to proceed after removing variant (iOS 9 specific)
        // This error handling is intended to fix issue with AVPlayer not being able to restore playback
        // after application has gone to background and device was locked.
        // The reason why such errorStatusCodes are handled is that they will be emitted in case
        // when network sockets were closed and it's not possible to restore playback session. That's
        // the reason playback session is invalidated by calling endPlaybackSession method - this will
        // clean up current AVPlayerItem, which in turn re-created by calling avPlayerItem method of the
        // DownloadableAgent class. After that playback is resumed by calling seekToTime: with latest
        // currentTime value.
        // </quote>
        //
        // U-Next comment:
        // We also have to consider the playtoken expring and our current architecture does not allow just
        // recreating the player item. By restarting the playback
        // -1004 is NSURLErrorCannotConnectToHost
        // -12880 is unknown error code.
        //

        guard let avPlayer = self.player else { return }
        guard let currentItem = avPlayer.currentItem else { return }
        guard let event = currentItem.errorLog()?.events.last else { return }

        // An alternative approach is to create an NSError from event.errorDomain and event.errorStatusCode and
        // handle it in a switch. But we do not know the domain and name of -12880 so we can't do that now.
        guard [URLError.cannotConnectToHost.rawValue, -12880].contains(event.errorStatusCode) else { return }

        refreshPlaylistURL(shouldPause: true)
    }

    /// 通信が切断される
    func networkDidDisconnect() {
        // ロード中で通信が切断させる際
        guard self.moviePlayMode == .streamingPlay &&
            (self.playerItem == nil || self.playerItem?.isPlaybackBufferEmpty == true) else {
            return
        }
        self.informPlayerError(PlayError.connectionFailed)
    }
    
    /// AVPlayerItemのログを出力
    private func printLogOfPlayerItem(_ playerItem: AVPlayerItem?) {
        guard LogOn else { return }
        
        if let accessLog = playerItem?.accessLog(), let data = accessLog.extendedLogData() {
            let string = NSString(data: data, encoding: accessLog.extendedLogDataStringEncoding)
            UNLog("Access log: \(String(describing: string))")
        }
        if let errorLog = playerItem?.errorLog(), let data = errorLog.extendedLogData() {
            let string = NSString(data: data, encoding: errorLog.extendedLogDataStringEncoding)
            UNLog("Error log: \(String(describing: string))")
        }
    }
}

// MARK: - UNMediaItemDelegate

extension UNPlayerResources: UNMediaItemDelegate {

    func item(_ item: UNMediaItem, didFailWithError error: UNLocalizedError) {
        self.informPlayerError(error)
    }
}
