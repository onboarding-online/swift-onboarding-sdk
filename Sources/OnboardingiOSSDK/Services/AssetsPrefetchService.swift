//
//  AssetsPrefetchService.swift
//  OnboardingOnline
//
//  Onboarding.online
//  Copyright 2023 Onboarding.online. All rights reserved.
//
import UIKit
import ScreensGraph

typealias AssetsPrefetchResult = Result<Void, AssetsPrefetchError>
typealias AssetsPrefetchResultCallback = (AssetsPrefetchResult)->()

final class AssetsPrefetchService {
    
    let screenGraph: ScreensGraph
    
    private var waiters: [String : [ResultCallbackHolder]] = [:]
    private var waitersTimeouts: [String : [DispatchWorkItem]] = [:]
    private var preloadedScreenIds: Set<String> = []
    private var failedScreenIds: Set<String> = []
    private var didStartPrefetching = false
    private let serialQueue = DispatchQueue(label: "com.onboarding.online.assets.prefetch.serial")
    private let assetsLoader = AssetsLoader()
        
    init(screenGraph: ScreensGraph) {
        self.screenGraph = screenGraph
    }
    
}

// MARK: - Open methods
extension AssetsPrefetchService {
    func prefetchAllAssets(completion: @escaping AssetsPrefetchResultCallback) {
        log(message: "Will start prefetching of all screens")

        let screens = self.screenGraph.screens.map({ $0.value })
        
        let startLoadingAssets = Date()
        prefetchAssetsFor(screens: screens, completion: { [weak self] result in
            let time = Date().timeIntervalSince(startLoadingAssets)
            
            switch result {
            case .success:
                OnboardingService.shared.eventRegistered(event: .allAssetsLoaded, params: [.time: time, .assetsLoadedSuccess: true])
                self?.log(message: "Did prefetch all screens")
            case .failure(let error):
                OnboardingService.shared.eventRegistered(event: .allAssetsLoaded, params: [.time: time, .assetsLoadedSuccess: false])
                self?.log(message: "Did fail to prefetch all screens with error: \(error.localizedDescription)")
            }
            completion(result)
        })
    }
    
    func startLazyPrefetching() {
        didStartPrefetching = true
        log(message: "Will start prefetching")
        prefetchFirstScreen { [weak self] result in
            self?.log(message: "Did prefetch first screen. Will start prefetching of the rest")
            self?.prefetchAllAssets(completion: { _ in })
        }
    }
    
    func onScreenReady(screenId: String, timeout: TimeInterval? = nil, callback: @escaping AssetsPrefetchResultCallback) {
        if isScreenAssetsPrefetched(screenId: screenId) {
            callback(.success(Void()))
        } else if isScreenAssetsPrefetchFailed(screenId: screenId) {
            callback(.failure(.prefetchFailed))
        } else {
            let callbackHolder = ResultCallbackHolder(callback: callback)
            
            if let timeout = timeout {
                let task = DispatchWorkItem { [weak self] in
                    self?.removeWaiterWith(id: callbackHolder.id, from: screenId)
                    callback(.success(Void()))
                }
                log(message: "Will set waiter timeout \(screenId)")
                serialQueue.sync {
                    waitersTimeouts[screenId, default: []].append(task)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: task)
            }
            
            log(message: "Will add waiter for \(screenId)")
            serialQueue.sync {
                waiters[screenId, default: []].append(callbackHolder)
            }
            
            if !didStartPrefetching {
                startLazyPrefetching()
            }
        }
    }
    
    func isScreenAssetsPrefetched(screenId: String) -> Bool {
        preloadedScreenIds.contains(screenId)
    }
    
    func isScreenAssetsPrefetchFailed(screenId: String) -> Bool {
        failedScreenIds.contains(screenId)
    }
}

// MARK: - Private methods
private extension AssetsPrefetchService {
    
    func prefetchFirstScreen(completion: @escaping AssetsPrefetchResultCallback) {
        guard let firstScreen = screenGraph.screens[screenGraph.launchScreenId] else {
            completion(.success(Void()))
            return
        }
        
        prefetchAssetsFor(screen: firstScreen, completion: completion)
    }
    
    func prefetchAssetsFor(screens: [Screen], completion: @escaping AssetsPrefetchResultCallback) {
        let notPrefetchedScreens = screens.filter({ !isScreenAssetsPrefetched(screenId: $0.id) })
        
        guard !notPrefetchedScreens.isEmpty else {
            completion(.success(Void()))
            return
        }
        
        let group = DispatchGroup()
        var loadingError: AssetsPrefetchError?
        
        for screen in notPrefetchedScreens {
            group.enter()
            prefetchAssetsFor(screen: screen) { result in
                if case .failure(let error) = result {
                    loadingError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = loadingError {
                completion(.failure(error))
            } else {
                completion(.success(Void()))
            }
        }
    }
    
    func prefetchAssetsFor(screen: Screen, completion: @escaping AssetsPrefetchResultCallback) {
        guard !preloadedScreenIds.contains(screen.id) else {
            completion(.success(Void()))
            return
        }
        
        log(message: "Will prefetch assets for \(screen.id)")
        prefetchAssetsFor(screenStruct: screen._struct, completion: { [weak self] result in
            switch result {
            case .success:
                self?.log(message: "Did prefetch assets for \(screen.id)")
                self?.preloadedScreenIds.insert(screen.id)
            case .failure(let error):
                self?.log(message: "Did fail to prefetch assets for \(screen.id) with error: \(error.localizedDescription)")
                self?.failedScreenIds.insert(screen.id)
            }
            self?.notifyWaitersFor(screenId: screen.id, result: result)
            completion(result)
        })
    }
    
    func prefetchAssetsFor(screenStruct: ScreenStruct, completion: @escaping AssetsPrefetchResultCallback) {
        switch screenStruct {
        case .typeScreenImageTitleSubtitles(let value):
            prefetchAssetsFor(type: value, imageList: nil, completion: completion)
        case .typeScreenProgressBarTitle(let value):
            prefetchAssetsFor(type: value, imageList: nil, completion: completion)
        case .typeScreenImageTitleSubtitlePicker(let value):
            prefetchAssetsFor(type: value, imageList: nil, completion: completion)
        case .typeScreenTitleSubtitleCalendar(let value):
            prefetchAssetsFor(type: value, imageList: nil, completion: completion)
        case .typeScreenTitleSubtitleField(let value):
            prefetchAssetsFor(type: value, imageList: nil, completion: completion)
        case .typeScreenTooltipPermissions(let value):
            let imageList = [value.tooltip.image]

            prefetchAssetsFor(type: value, imageList: imageList, completion: completion)
        case .typeCustomScreen(let value):
            prefetchAssetsFor(type: value, imageList: nil, completion: completion)

        case .typeScreenTableMultipleSelection(let value):
            if ImageLabelCollectionCell.isImageHiddenFor(itemType: value.list.itemType) {
                prefetchAssetsFor(type: value, imageList: nil, completion: completion)
            } else {
                prefetchAssetsFor(type: value, imageList: value.list.items, completion: completion)
            }
            
        case .typeScreenTableSingleSelection(let value):
           
            if CellConfigurator.isImageHiddenFor(itemType: value.list.itemType) {
                prefetchAssetsFor(type: value, imageList: nil, completion: completion)
            } else {
                prefetchAssetsFor(type: value, imageList: value.list.items, completion: completion)
            }
            
        case .typeScreenImageTitleSubtitleList(let value):

            prefetchAssetsFor(type: value, imageList: value.list.items, completion: completion)            
        case .typeScreenTwoColumnMultipleSelection(let value):
            if CellConfigurator.isImageHiddenFor(itemType: value.list.itemType) {
                prefetchAssetsFor(type: value, imageList: nil, completion: completion)
            } else {
                prefetchAssetsFor(type: value, imageList: value.list.items, completion: completion)
            }
            
        case .typeScreenTwoColumnSingleSelection(let value):
            
            if CellConfigurator.isImageHiddenFor(itemType: value.list.itemType) {
                prefetchAssetsFor(type: value, imageList: nil, completion: completion)
            } else {
                prefetchAssetsFor(type: value, imageList: value.list.items, completion: completion)
            }
            
        case .typeScreenImageTitleSubtitleMultipleSelectionList(let value):
            if ImageLabelCollectionCell.isImageHiddenFor(itemType: value.list.itemType) {
                prefetchAssetsFor(type: value, imageList: nil, completion: completion)
            } else {
                prefetchAssetsFor(type: value, imageList: value.list.items, completion: completion)
            }
            
        case .typeScreenSlider(let value):
            
            let imageList = value.slider.items.compactMap({$0.content})
            prefetchAssetsFor(type: value, imageList: imageList, completion: completion)
        case .typeScreenTitleSubtitlePicker(let value):
            
            prefetchAssetsFor(type: value, imageList: nil, completion: completion)
        }
    }
    
    func prefetchAssetsFor(type: Any, imageList: Any?, completion: @escaping AssetsPrefetchResultCallback) {
        var allAsets = [AssetPrfetch]()
        if let sceenDataType = type as? ImageProtocol {
            let image: [AssetPrfetch] = [.from(image: sceenDataType.image)].compactMap({ $0 })
            allAsets += image
        }
        
        if let sceenDataType = type as? BaseScreenStyleProtocol {
            let backgroundAssets = assetsFor(backgroundStyle: sceenDataType.styles.background)
            allAsets += backgroundAssets
        }
        
        let listAsset = prefetchAssetsFor(list: imageList)
        allAsets += listAsset
        
        load(assets: allAsets, completion: completion)
    }
    
    func prefetchAssetsFor(list: Any?) -> [AssetPrfetch]  {
        if let imageList = list as? (any Sequence)  {
            let images = imageList.compactMap { item in
                if let image =  item as? ImageProtocol {
                    return image
                }
                return nil
            }
            
            let imageAssets = prefetchAssetsFor(type: images)
            
            return imageAssets
        }
        return []
    }
    
    func prefetchAssetsFor(type: [ImageProtocol]) -> [AssetPrfetch]  {
        let images = type.map({ $0.image })
        let imageAssets = images.compactMap({ AssetPrfetch.from(image: $0) })
        return imageAssets
    }

    
    func assetsFor(backgroundStyle: BackgroundStyle) -> [AssetPrfetch] {
        switch backgroundStyle.styles {
        case .typeBackgroundStyleColor:
            return []
        case .typeBackgroundStyleImage(let value):
            return [.from(baseImage: value.image)].compactMap({ $0 })
        case .typeBackgroundStyleVideo(let value):
            return [.from(baseVideo: value.video)].compactMap({ $0 })
        }
    }
    
    func notifyWaitersFor(screenId: String, result: AssetsPrefetchResult) {
        log(message: "Will notify waiters for \(screenId)")

        let timeoutTasks = serialQueue.sync { waitersTimeouts[screenId] ?? [] }
        timeoutTasks.forEach { item in
            if !item.isCancelled {
                item.cancel()
            }
        }
        
        let callbacks = serialQueue.sync { waiters[screenId] ?? [] }
        
        callbacks.forEach { holder in
            holder.callback(result)
        }
        
        serialQueue.sync {
            waiters[screenId] = nil
            waitersTimeouts[screenId] = nil
        }
    }
    
    func removeWaiterWith(id: UUID, from screenId: String) {
        log(message: "Will remove waiter for \(screenId) due to timeout")
        serialQueue.sync {
            waiters[screenId, default: []].removeAll(where: { $0.id == id })
        }
    }
    
    func log(message: String) {
//        OnboardingService.shared.systemEventRegistered(event: message, params: ["message": message])
        OnboardingLogger.logInfo(topic: .assetsPrefetch, message)
    }
}

// MARK: - Private methods
private extension AssetsPrefetchService {
    func load(asset: AssetPrfetch, completion: @escaping AssetsPrefetchResultCallback) {
        switch asset {
        case .image(let assetUrl):
            assetsLoader.loadImage(assetUrl: assetUrl, completion: completion)
        case .video(let assetUrl):
            assetsLoader.loadVideo(assetUrl: assetUrl, completion: completion)
        }
    }
    
    func load(assets: [AssetPrfetch], completion: @escaping AssetsPrefetchResultCallback) {
        guard !assets.isEmpty else {
            completion(.success(Void()))
            return
        }
        let group = DispatchGroup()
        
        var loadingError: AssetsPrefetchError?
        for asset in assets {
            group.enter()
            load(asset: asset) { result in
                if case .failure(let error) = result {
                    loadingError = error
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if let error = loadingError {
                completion(.failure(error))
            } else {
                completion(.success(Void()))
            }
        }
    }
    

}

// MARK: - Private methods
private extension AssetsPrefetchService {
    
    struct AssetsLoader {
        func loadImage(assetUrl: AssetUrl, completion: @escaping AssetsPrefetchResultCallback) {
            let url = assetUrl.origin
            AssetsLoadingService.shared.loadImage(from: url) { result in
                switch result {
                case .success:
                    completion(.success(Void()))
                case .failure(let error):
                    completion(.failure(.imageLoadingError(error)))
                }
            }
        }
        
        func loadVideo(assetUrl: AssetUrl, completion: @escaping AssetsPrefetchResultCallback) {
            let url = assetUrl.origin
          
//            AssetsLoadingService.shared.loadData(from: url,
//                                                 assetType: .videoThumbnail) { _ in }
            AssetsLoadingService.shared.loadData(from: url,
                                                 assetType: .video) { result in
                switch result {
                case .success:
                    completion(.success(Void()))
                case .failure(let error):
                    completion(.failure(.imageLoadingError(error)))
                }
            }
        }
    }
    
    struct ResultCallbackHolder {
        let id: UUID = UUID()
        let callback: AssetsPrefetchResultCallback
    }
}

enum AssetsPrefetchError: LocalizedError {
    case imageLoadingError(_ error: AssetLoadingError)
    case prefetchFailed
    
    public var errorDescription: String? {
        switch self {
        case .imageLoadingError(let error):
            return "imageLoadingError: \(error.localizedDescription)"
        case .prefetchFailed:
            return "prefetchFailed"
        }
    }
}

enum AssetPrfetch {
    
    case image(_ assetUrl: AssetUrl)
    case video(_ assetUrl: AssetUrl)
    
    static func from(image: Image) -> AssetPrfetch? {
        guard let assetUrl = image.assetUrlByLocal()?.assetUrl else { return nil }
        return .image(assetUrl)
    }
    
    static func from(baseImage: BaseImage) -> AssetPrfetch? {
        guard let assetUrl = baseImage.assetUrlByLocal()?.assetUrl else { return nil }
        return .image(assetUrl)
    }
    
    static func from(baseVideo: BaseVideo) -> AssetPrfetch? {
        guard let assetUrl = baseVideo.assetUrlByLocal()?.assetUrl else { return nil }
        return .video(assetUrl)
    }
    
}
