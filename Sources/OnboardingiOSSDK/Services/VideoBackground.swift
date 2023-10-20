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

    public var willLoopVideo = true

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
                self?.playerLayer.player?.play()
        }
    }

    public func play(view: UIView,
                     videoName: String,
                     videoType: String,
                     isMuted: Bool = true,
                     darkness: CGFloat = 0,
                     willLoopVideo: Bool = true,
                     setAudioSessionAmbient: Bool = true,
                     preventsDisplaySleepDuringVideoPlayback: Bool = true) throws {
        guard let path = Bundle.main.path(forResource: videoName, ofType: videoType) else {
            throw VideoBackgroundError.videoNotFound((name: videoName, type: videoType))
        }
        let url = URL(fileURLWithPath: path)
        play(
            view: view,
            url: url,
            darkness: darkness,
            isMuted: isMuted,
            willLoopVideo: willLoopVideo,
            setAudioSessionAmbient: setAudioSessionAmbient,
            preventsDisplaySleepDuringVideoPlayback: preventsDisplaySleepDuringVideoPlayback
        )
    }

    public func play(view: UIView,
                     url: URL,
                     darkness: CGFloat = 0,
                     isMuted: Bool = true,
                     willLoopVideo: Bool = true,
                     setAudioSessionAmbient: Bool = true,
                     preventsDisplaySleepDuringVideoPlayback: Bool = true) {
        cleanUp()

        if setAudioSessionAmbient {
            if #available(iOS 10.0, *) {
                try? AVAudioSession.sharedInstance().setCategory(
                    AVAudioSession.Category.ambient,
                    mode: AVAudioSession.Mode.default
                )
                try? AVAudioSession.sharedInstance().setActive(true)
            }
        }
        if #available(iOS 12.0, *) {
            player.preventsDisplaySleepDuringVideoPlayback = preventsDisplaySleepDuringVideoPlayback
        }

        self.willLoopVideo = willLoopVideo

        if cache[url] == nil {
            cache[url] = AVPlayerItem(url: url)
        }
        
        player.replaceCurrentItem(with: cache[url])
        player.actionAtItemEnd = .none
        player.isMuted = isMuted
        player.play()

        playerLayer.frame = view.bounds
        playerLayer.needsDisplayOnBoundsChange = true
        playerLayer.videoGravity = videoGravity
        playerLayer.zPosition = -1
        view.layer.insertSublayer(playerLayer, at: 0)

        darknessOverlayView = UIView(frame: view.bounds)
        darknessOverlayView.alpha = 0
        darknessOverlayView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        darknessOverlayView.backgroundColor = .black
        self.darkness = darkness
        view.addSubview(darknessOverlayView)
        view.sendSubviewToBack(darknessOverlayView)

        // Restart video when it ends
        playerItemDidPlayToEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main) { [weak self] _ in
                if let willLoopVideo = self?.willLoopVideo, willLoopVideo {
                    self?.restart()
                }
        }

        // Adjust frames upon device rotation
        viewBoundsObserver = view.layer.observe(\.bounds) { [weak self] view, _ in
            DispatchQueue.main.async {
                self?.playerLayer.frame = view.bounds
            }
        }
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
