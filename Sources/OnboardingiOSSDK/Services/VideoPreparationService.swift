//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 25.10.2023.
//

import UIKit
import ScreensGraph
import AVFoundation
import Combine

final class VideoPreparationService {
    
    let screenGraph: ScreensGraph
    
    private let queue = DispatchQueue(label: "com.onboarding.online.video.preparation")
    private var screenIdToPlayerDict: [String : PlayerPreparationDetails] = [:]
    private var playerStatusObservers = [AnyCancellable]()
    private var onStatusCallbacks: [String : (PlayerPreparationStatus)->()] = [:]
    
    init(screenGraph: ScreensGraph) {
        self.screenGraph = screenGraph
        prepareVideo()
    }
    
}

// MARK: - Open methods
extension VideoPreparationService {
    /// Provide callback with video background status.
    /// Immediately return current status.
    func observeScreenId(_ screenId: String, callback: @escaping (PlayerPreparationStatus)->()) {
        queue.sync {
            guard let details = screenIdToPlayerDict[screenId] else {
                callback(.failed)
                return
            }
            
            onStatusCallbacks[screenId] = callback
            callback(details.status)
        }
    }
}

// MARK: - Private methods
private extension VideoPreparationService {
    func prepareVideo() {
        for (screenId, screen) in screenGraph.screens {
            guard let baseScreenStruct = ChildControllerFabrika.viewControllerFor(screen: screen) else { continue }
            
            switch baseScreenStruct.baseScreen.styles.background.styles {
            case .typeBackgroundStyleColor, .typeBackgroundStyleImage:
                continue
            case .typeBackgroundStyleVideo(let value):
                let video = value.video
                let player = createNewPlayer()
                screenIdToPlayerDict[screenId] = PlayerPreparationDetails(player: player,
                                                                          video: video)
            }
        }
        
        preparePlayers()
    }
    
    func createNewPlayer() -> AVPlayer {
        let player = AVPlayer(playerItem: nil)
        if #available(iOS 12.0, *) {
            player.preventsDisplaySleepDuringVideoPlayback = true
        }
        player.actionAtItemEnd = .none
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false
        return player
    }
    
    func preparePlayers() {
        for (screenId, details) in screenIdToPlayerDict {
            preparePlayerFor(screenId: screenId, with: details)
        }
    }
    
    func preparePlayerFor(screenId: String, with preparationDetails: PlayerPreparationDetails) {
        updateStatusOf(screenId: screenId, to: .preparing)
        let video = preparationDetails.video
        
        if let name = video.assetUrlByLocal()?.assetName {
            if let videoURL = Bundle.main.url(forResource: name, withExtension: "mp4") {
                setPlayVideoBackgroundFor(screenId: screenId, with: videoURL)
                return
            }
        }
        
        guard let stringURL = video.assetUrlByLocal()?.assetUrl?.origin else {
            updateStatusOf(screenId: screenId, to: .failed)
            return
        }
        
        if let name = stringURL.resourceNameWithoutExtension() {
            if let videoURL = Bundle.main.url(forResource: name, withExtension: "mp4") {
                self.setPlayVideoBackgroundFor(screenId: screenId, with: videoURL)
                return
            }
        }
        
        AssetsLoadingService.shared.loadData(from: stringURL, assetType: .video) { result in
            DispatchQueue.main.async {
                if let name = stringURL.resourceName() {
                    if let videoURL = Bundle.main.url(forResource: name, withExtension: nil) {
                        self.setPlayVideoBackgroundFor(screenId: screenId, with: videoURL)
                        return
                    }
                }
                
                if let storedURL = AssetsLoadingService.shared.urlToStoredData(from: stringURL, assetType: .video) {
                    self.setPlayVideoBackgroundFor(screenId: screenId, with: storedURL)
                } else if let url = URL(string: stringURL) {
                    self.setPlayVideoBackgroundFor(screenId: screenId, with: url)
                }
            }
        }
    }
    
    func setPlayVideoBackgroundFor(screenId: String, with videoURL: URL) {
        guard let details = screenIdToPlayerDict[screenId] else { return }

        let player = details.player
        let playerItem = AVPlayerItem(url: videoURL)
        player.replaceCurrentItem(with: playerItem)
        
        let publisher = player.publisher(for: \.status).sink { [weak self] status in
            switch status {
            case .unknown:
                return
            case .failed:
                self?.updateStatusOf(screenId: screenId, to: .failed)
            case .readyToPlay:
                self?.updateStatusOf(screenId: screenId, 
                                     to: .ready(VideoBackgroundPreparedData(player: player,
                                                                            playerLayer: details.playerLayer)))
            @unknown default:
                return
            }
        }
        
        queue.sync {
            playerStatusObservers.append(publisher)
        }
    }
    
    func updateStatusOf(screenId: String, to newStatus: PlayerPreparationStatus) {
        queue.sync {
            guard var details = screenIdToPlayerDict[screenId] else { return }
            
            details.status = newStatus
            screenIdToPlayerDict[screenId] = details
            onStatusCallbacks[screenId]?(newStatus)
        }
    }
}

// MARK: - Private methods
private extension VideoPreparationService {
    struct PlayerPreparationDetails {
        let player: AVPlayer
        let playerLayer: AVPlayerLayer
        let video: BaseVideo
        var status: PlayerPreparationStatus = .undefined
        
        init(player: AVPlayer, video: BaseVideo, status: PlayerPreparationStatus = .undefined) {
            self.player = player
            self.playerLayer = AVPlayerLayer(player: player)
            self.video = video
            self.status = status
        }
    }
}

// MARK: - Open methods
extension VideoPreparationService {
    enum PlayerPreparationStatus {
        case undefined, preparing, failed
        case ready(VideoBackgroundPreparedData)
    }
}

public struct VideoBackgroundPreparedData {
    let player: AVPlayer
    let playerLayer: AVPlayerLayer
}
