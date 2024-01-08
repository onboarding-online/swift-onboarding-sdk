//
//  File.swift
//
//
//  Created by Leonid Yuriev on 31.08.23.
//


import AVFoundation
import UIKit

public class VideoBackground {
    
    public static let shared = VideoBackground()

    public var darkness: CGFloat = 0 {
        didSet {
            if darkness > 0 && darkness <= 1 {
                darknessOverlayView.alpha = darkness
            }
        }
    }

    public var isMuted = true {
        didSet {
            playerLayer.player?.isMuted = isMuted
        }
    }

    public var videoGravity: AVLayerVideoGravity = .resizeAspectFill

    public lazy var playerLayer = AVPlayerLayer(player: player)

    private var player = AVPlayer(playerItem: nil)

    public var cache = [URL: AVPlayerItem]()

    private lazy var darknessOverlayView = UIView()

    private var applicationWillEnterForegroundObserver: NSObjectProtocol?

    private var playerItemDidPlayToEndObserver: NSObjectProtocol?

    private var viewBoundsObserver: NSKeyValueObservation?

    public init() {
        // Resume video when application re-enters foreground
        applicationWillEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.playerLayer.player?.seek(to: .zero)
                self?.playerLayer.player?.play()
        }
    }

    public func play(view: UIView,
                     videoName: String,
                     videoType: String,
                     isMuted: Bool = true,
                     configuration: Configuration = .default,
                     preventsDisplaySleepDuringVideoPlayback: Bool = true) throws {
        guard let path = Bundle.main.path(forResource: videoName, ofType: videoType) else {
            throw VideoBackgroundError.videoNotFound((name: videoName, type: videoType))
        }
        let url = URL(fileURLWithPath: path)
        play(view: view,
             url: url,
             isMuted: isMuted,
             configuration: configuration,
             preventsDisplaySleepDuringVideoPlayback: preventsDisplaySleepDuringVideoPlayback)
    }
    
    public func play(view: UIView,
                     url: URL,
                     isMuted: Bool = true,
                     configuration: Configuration = .default,
                     preventsDisplaySleepDuringVideoPlayback: Bool = true) {
        cleanUp()
        prepareWith(configuration: configuration, in: view)
        
        let player = self.player
        if #available(iOS 12.0, *) {
            player.preventsDisplaySleepDuringVideoPlayback = preventsDisplaySleepDuringVideoPlayback
        }
        
        if cache[url] == nil {
            cache[url] = AVPlayerItem(url: url)
        }
        
        player.replaceCurrentItem(with: cache[url])
        player.actionAtItemEnd = .none
        player.isMuted = isMuted
        player.automaticallyWaitsToMinimizeStalling = false
        player.play()
    }
    
    public func play(in view: UIView,
                     configuration: Configuration = .default,
                     using preparedData: VideoBackgroundPreparedData) {
        cleanUp()
        self.player = preparedData.player
        self.playerLayer = preparedData.playerLayer
        prepareWith(configuration: configuration, in: view)
        player.play()
    }
    
    /// Pauses the video.
    public func pause() {
        playerLayer.player?.pause()
    }

    /// Resumes the video.
    public func resume() {
        playerLayer.player?.play()
    }

    /// Restarts the video from the beginning.
    public func restart() {
        playerLayer.player?.seek(to: CMTime.zero)
        playerLayer.player?.play()
    }

    /// Generate an image from the video to show as thumbnail
    ///
    /// - Parameters:
    ///   - url: video file URL
    ///   - time: time of video frame to make into thumbnail image
    public func getThumbnailImage(from url: URL, at time: CMTime) throws -> UIImage {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let thumbnailImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: thumbnailImage)
    }

    private func cleanUp() {
        playerLayer.player?.pause()
        playerLayer.removeFromSuperlayer()
        darknessOverlayView.removeFromSuperview()
        if let playerItemDidPlayToEndObserver = playerItemDidPlayToEndObserver {
            NotificationCenter.default.removeObserver(playerItemDidPlayToEndObserver)
        }
        viewBoundsObserver?.invalidate()
    }

    deinit {
        cleanUp()
        if let applicationWillEnterForegroundObserver = applicationWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(applicationWillEnterForegroundObserver)
        }
    }
}

// MARK: - Private methods
private extension VideoBackground {
    func prepareWith(configuration: Configuration, in view: UIView) {
        setupAudioSessionAmbient(if: configuration.setAudioSessionAmbient)
        preparePlayerLayer(in: view)
        prepareDarknessOverlayView(in: view,
                                   darkness: configuration.darkness)
        prepareLoopVideoObserver(if: configuration.willLoopVideo)
    }
    
    func setupAudioSessionAmbient(if setAudioSessionAmbient: Bool) {
        if setAudioSessionAmbient {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
        }
    }
    
    func preparePlayerLayer(in view: UIView) {
        playerLayer.frame = view.bounds
        playerLayer.needsDisplayOnBoundsChange = true
        playerLayer.videoGravity = videoGravity
        playerLayer.zPosition = -1
        view.layer.insertSublayer(playerLayer, at: 0)
        
        // Adjust frames upon device rotation
        viewBoundsObserver = view.layer.observe(\.bounds) { [weak self] view, _ in
            DispatchQueue.main.async {
                self?.playerLayer.frame = view.bounds
            }
        }
    }
    
    func prepareDarknessOverlayView(in view: UIView,
                                    darkness: CGFloat) {
        darknessOverlayView = UIView(frame: view.bounds)
        darknessOverlayView.alpha = 0
        darknessOverlayView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        darknessOverlayView.backgroundColor = .black
        self.darkness = darkness
        view.addSubview(darknessOverlayView)
        view.sendSubviewToBack(darknessOverlayView)
    }

    func prepareLoopVideoObserver(if willLoopVideo: Bool) {
        if willLoopVideo {
            playerItemDidPlayToEndObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main) { [weak self] _ in
                    self?.restart()
                }
        }
    }
}

// MARK: - Configuration
public extension VideoBackground {
    struct Configuration {
        let darkness: CGFloat
        let willLoopVideo: Bool
        let setAudioSessionAmbient: Bool
        
        public static let `default` = Configuration(darkness: 0,
                                             willLoopVideo: true,
                                             setAudioSessionAmbient: true)
    }
}

/// Errors that can occur when playing a video.
public enum VideoBackgroundError: LocalizedError {
    /// Video with given name and type could not be found.
    case videoNotFound((name: String, type: String))

    /// Description of the error.
    public var errorDescription: String? {
        switch self {
        case . videoNotFound(let videoInfo):
            return "Could not find \(videoInfo.name).\(videoInfo.type)."
        }
    }
}
