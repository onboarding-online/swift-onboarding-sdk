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

public final class VideoPreparationService {
    
    let screenGraph: ScreensGraph
    
    private let queue = DispatchQueue(label: "com.onboarding.online.video.preparation")
    private var screenIdToPlayerDict: [String : PlayerPreparationDetails] = [:]
    private var playerStatusObservers = [AnyCancellable]()
    private var onStatusCallbacks: [String : [(PlayerPreparationStatus)->()]] = [:]
    private var screenIdToEdgesDict: [String : [ConditionedAction]] = [:]
    
    public init(screenGraph: ScreensGraph) {
        self.screenGraph = screenGraph
//        prepareVideo()
        
        findAllEdges()
//        prepareInSequence()
        prepareVideo()
        
//        prepareVideoFor(screenIds: [screenGraph.launchScreenId])
//        prepareVideoForScreens(after: screenGraph.launchScreenId)
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
            
            onStatusCallbacks[screenId, default: []].append(callback)
            callback(details.status)
        }
    }
    
    func getStatusFor(screenId: String) -> PlayerPreparationStatus? {
        screenIdToPlayerDict[screenId]?.status
    }
    
    func prepareForNextScreen(_ screenId: String?) {
//        guard let screenId else { return }
    
//        prepareVideoForScreens(after: screenId)
    }
}

// MARK: - Private methods
private extension VideoPreparationService {
    
    func prepareVideo() {
        for (screenId, screen) in screenGraph.screens {
            guard let background = ChildControllerFabrika.background(screen: screen) else { continue }
            
            switch background.styles {
            case .typeBackgroundStyleColor, .typeBackgroundStyleImage:
                continue
            case .typeBackgroundStyleVideo(let value):
                let video = value.video
                let player = createNewPlayer()
                screenIdToPlayerDict[screenId] = PlayerPreparationDetails(player: player, video: video,
                                                                          useLocalAssetsIfAvailable: screen.useLocalAssetsIfAvailable)
            }
        }
        
        for (_, screen) in screenGraph.screens {
            if let videoStruct = ChildControllerFabrika.videos(screen: screen) {
                if  let video = videoStruct.video  {
                    let player = createNewPlayer()
                    screenIdToPlayerDict[videoStruct.screenIdWithElementType] = PlayerPreparationDetails(player: player, video: video,
                                                                                                         useLocalAssetsIfAvailable: screen.useLocalAssetsIfAvailable)
                }
            }
           
        }
        
        preparePlayers()
    }
    
    func prepareInSequence() {
        let screenId = screenGraph.launchScreenId
        prepareVideoFor(screenIds: [screenId])
        
//        observeScreenId(screenId) { [weak self] status in
//            DispatchQueue.main.async {
//                switch status {
//                case .ready, .failed:
//                    self?.prepareVideo()
//                default:
//                    return
//                }
//            }
//        }
     
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.prepareVideo()
        }
    }
    
    func findAllEdges() {
        for (screenId, screen) in screenGraph.screens {
            if let edges = try? screen.findAllEdges() {
                screenIdToEdgesDict[screenId] = edges
            }
        }
    }
    
    func prepareVideoForScreens(after screenId: String) {
        guard let edges = screenIdToEdgesDict[screenId] else {
            
            return }
        
        let nextScreenIds = Set(edges.map { $0.nextScreenId })
        prepareVideoFor(screenIds: nextScreenIds)
    }
    
    func prepareVideoFor(screenIds: Set<String>) {
        for screenId in screenIds where screenIdToPlayerDict[screenId] == nil {
            guard let screen = screenGraph.screens[screenId],
                  let baseScreenStruct = ChildControllerFabrika.viewControllerFor(screen: screen) else { continue }
            
            switch baseScreenStruct.baseScreen.styles.background.styles {
            case .typeBackgroundStyleColor, .typeBackgroundStyleImage:
                continue
            case .typeBackgroundStyleVideo(let value):
                let video = value.video
                let player = createNewPlayer()
                screenIdToPlayerDict[screenId] = PlayerPreparationDetails(player: player,
                                                                          video: video,
                                                                          useLocalAssetsIfAvailable: screen.useLocalAssetsIfAvailable)
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
            if case .undefined = details.status {
                preparePlayerFor(screenId: screenId, with: details)
            }
        }
    }
    
    func preparePlayerFor(screenId: String, with preparationDetails: PlayerPreparationDetails) {
        updateStatusOf(screenId: screenId, to: .preparing)
        let video = preparationDetails.video
        if let videoURL = video.getCachedURLToVideoAsset() {
            self.setPlayVideoBackgroundFor(screenId: screenId, with: videoURL)
        } else {
            Task { @MainActor in
                if let videoURL = await video.urlToVideoAsset(useLocalAssetsIfAvailable: preparationDetails.useLocalAssetsIfAvailable) {
                    self.setPlayVideoBackgroundFor(screenId: screenId, with: videoURL)
                } else {
                    updateStatusOf(screenId: screenId, to: .failed)
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
//        player.play()
        queue.sync {
            playerStatusObservers.append(publisher)
        }
    }
    
    func updateStatusOf(screenId: String, to newStatus: PlayerPreparationStatus) {
        queue.sync {
            guard var details = screenIdToPlayerDict[screenId] else { return }
            
            details.status = newStatus
            screenIdToPlayerDict[screenId] = details
            onStatusCallbacks[screenId]?.forEach { callback in
                callback(newStatus)
            }
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
        let useLocalAssetsIfAvailable: Bool
        
        init(player: AVPlayer, video: BaseVideo, status: PlayerPreparationStatus = .undefined,
             useLocalAssetsIfAvailable: Bool) {
            self.player = player
            self.playerLayer = AVPlayerLayer(player: player)
            self.video = video
            self.status = status
            self.useLocalAssetsIfAvailable = useLocalAssetsIfAvailable
        }
    }
}

// MARK: - Open methods
extension VideoPreparationService {
    enum PlayerPreparationStatus {
        case undefined, preparing, failed
        case ready(VideoBackgroundPreparedData)
        
        fileprivate var debugName: String {
            switch self {
            case .undefined:
                return "undefined"
            case .preparing:
                return "preparing"
            case .failed:
                return "failed"
            case .ready:
                return "ready"
            }
        }
    }
}

public struct VideoBackgroundPreparedData {
    let player: AVPlayer
    let playerLayer: AVPlayerLayer
}

fileprivate extension Screen {
    func findAllEdges() throws -> [ConditionedAction] {
        let data = try JSONEncoder().encode(self)
        let jsonSerialized = try JSONSerialization.jsonObject(with: data)
        guard let json = jsonSerialized as? [String : Any] else {
            throw FindEdgesError.incorrectScreenJSON
        }
        let edges = findAllEdges(in: json)
        return edges
    }
    
    private func findAllEdges(in json: [String : Any]) -> [ConditionedAction] {
        var edges = [ConditionedAction]()
        let edgesPropertyKey = "edges"
        
        for (key, value) in json {
            if key == edgesPropertyKey,
               let json = value as? [[String : Any]],
               let thisEdgesData = try? JSONSerialization.data(withJSONObject: json),
               let thisEdges = try? JSONDecoder().decode([ConditionedAction].self, from: thisEdgesData) {
                edges.append(contentsOf: thisEdges)
            } else if let json = value as? [String : Any] {
                let thisEdges = findAllEdges(in: json)
                edges.append(contentsOf: thisEdges)
            } else if let jsonArray = value as? [[String : Any]] {
                for json in jsonArray {
                    let thisEdges = findAllEdges(in: json)
                    edges.append(contentsOf: thisEdges)
                }
            }
        }
        
        return edges
    }
    
    enum FindEdgesError: String, LocalizedError {
        case incorrectScreenJSON
        
        var errorDescription: String? { rawValue }
    }
}
