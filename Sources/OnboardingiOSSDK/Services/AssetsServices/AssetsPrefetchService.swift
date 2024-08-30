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

public final class AssetsPrefetchService {
    
    let screenGraph: ScreensGraph
    
    private var waiters: [String : [ResultCallbackHolder]] = [:]
    private var waitersTimeouts: [String : [DispatchWorkItem]] = [:]
    private var preloadedScreenIds: Set<String> = []
    private var failedScreenIds: Set<String> = []
    private var didStartPrefetching = false
    private let serialQueue = DispatchQueue(label: "com.onboarding.online.assets.prefetch.serial")
        
    init(screenGraph: ScreensGraph) {
        self.screenGraph = screenGraph
    }
    
}

// MARK: - Open methods
extension AssetsPrefetchService {
    func prefetchAllAssets() async throws {
        log(message: "Will start prefetching of all screens")

        let screens = self.screenGraph.screens.map({ $0.value })
        
        let startLoadingAssets = Date()
        do { 
            try await prefetchAssetsFor(screens: screens)
            let time = Date().timeIntervalSince(startLoadingAssets)
            OnboardingService.shared.eventRegistered(event: .allAssetsLoaded, params: [.time: time, .assetsLoadedSuccess: true])
            log(message: "Did prefetch all screens")
        } catch {
            OnboardingService.shared.eventRegistered(event: .allAssetsLoaded, params: [.time: time, .assetsLoadedSuccess: false])
            log(message: "Did fail to prefetch all screens with error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func startLazyPrefetching() {
        didStartPrefetching = true
        log(message: "Will start prefetching")
        Task {
            try? await prefetchFirstScreen()
            log(message: "Did prefetch first screen. Will start prefetching of the rest")
            Task.detached {
                await Task.sleep(seconds: 0.2)
                try? await self.prefetchAllAssets()
            }
        }
    }
    
    func onScreenReady(screenId: String, timeout: TimeInterval? = nil) async throws {
        if isScreenAssetsPrefetched(screenId: screenId) {
            return
        } else if isScreenAssetsPrefetchFailed(screenId: screenId) {
            throw AssetsPrefetchError.prefetchFailed
        } else {
            let callbackHolder = ResultCallbackHolder()
            
            if let timeout = timeout {
                let task = DispatchWorkItem { [weak self] in
                    self?.notifyWaitersFor(screenId: screenId, result: .success(Void()))
                    self?.removeWaiterWith(id: callbackHolder.id, from: screenId)
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
            
            try await callbackHolder.wait()
        }
    }
    
    func isScreenAssetsPrefetched(screenId: String) -> Bool {
        serialQueue.sync { preloadedScreenIds.contains(screenId) }
    }
    
    func isScreenAssetsPrefetchFailed(screenId: String) -> Bool {
        serialQueue.sync { failedScreenIds.contains(screenId) }
    }
    
    func clear() {
        AssetsLoadingService.shared.clear()
    }
    
    public func prefetchAssetsFor(screen: Screen) async throws {
        guard !isScreenAssetsPrefetched(screenId: screen.id) else {
            return
        }
        
        log(message: "Will prefetch assets for \(screen.id)")
        do {
            try await prefetchAssetsFor(screenStruct: screen._struct)
            log(message: "Did prefetch assets for \(screen.id)")
            serialQueue.sync {
                _ = preloadedScreenIds.insert(screen.id)
            }
            notifyWaitersFor(screenId: screen.id, result: .success(Void()))
        } catch {
            log(message: "Did fail to prefetch assets for \(screen.id) with error: \(error.localizedDescription)")
            serialQueue.sync {
                _ = failedScreenIds.insert(screen.id)
            }
            notifyWaitersFor(screenId: screen.id, result: .failure(.prefetchFailed))
            throw error
        }
    }
    
}

// MARK: - Private methods
private extension AssetsPrefetchService {
    func prefetchFirstScreen() async throws {
        guard let firstScreen = screenGraph.screens[screenGraph.launchScreenId] else {
            return
        }
        
        try await prefetchAssetsFor(screen: firstScreen)
    }
    
    func prefetchAssetsFor(screens: [Screen]) async throws {
        let notPrefetchedScreens = screens.filter({ !isScreenAssetsPrefetched(screenId: $0.id) })
        guard !notPrefetchedScreens.isEmpty else { return }
        
        var loadingErrors: [Error] = []
        
        await withTaskGroup(of: Error?.self) { taskGroup in
            for screen in notPrefetchedScreens {
                taskGroup.addTask {
                    do {
                        try await self.prefetchAssetsFor(screen: screen)
                        return nil
                    } catch {
                        return error
                    }
                }
            }
            
            for await error in taskGroup {
                if let error {
                    loadingErrors.append(error)
                }
            }
        }
        if !loadingErrors.isEmpty {
            throw AssetLoadingError.failedToLoadAsset
        }
    }
    
   
    
    func prefetchAssetsFor(screenStruct: ScreenStruct) async throws {
        switch screenStruct {
        case .typeScreenBasicPaywall(let value):
            try await prefetchAssetsFor(type: value, imageList: value.list.items)
        case .typeScreenImageTitleSubtitles(let value):
            try await prefetchAssetsFor(type: value, imageList: nil)
        case .typeScreenProgressBarTitle(let value):
            
            let imageList = value.progressBar.items.compactMap({ (value) in
                if let image = value.content.image {
                  return ImageList.init(image: image)
                } else {
                    return nil
                }
            })

            try await prefetchAssetsFor(type: value, imageList: imageList)
        case .typeScreenImageTitleSubtitlePicker(let value):
            try await prefetchAssetsFor(type: value, imageList: nil)
        case .typeScreenTitleSubtitleCalendar(let value):
            try await prefetchAssetsFor(type: value, imageList: nil)
        case .typeScreenTitleSubtitleField(let value):
            try await prefetchAssetsFor(type: value, imageList: nil)
        case .typeScreenTooltipPermissions(let value):
            let imageList = [value.tooltip.image]

            try await prefetchAssetsFor(type: value, imageList: imageList)
        case .typeCustomScreen(let value):
            try await prefetchAssetsFor(type: value, imageList: nil)

        case .typeScreenTableMultipleSelection(let value):
            if await ImageLabelCollectionCell.isImageHiddenFor(itemType: value.list.itemType) {
                try await prefetchAssetsFor(type: value, imageList: nil)
            } else {
                try await prefetchAssetsFor(type: value, imageList: value.list.items)
            }
            
        case .typeScreenTableSingleSelection(let value):
           
            if CellConfigurator.isImageHiddenFor(itemType: value.list.itemType) {
                try await prefetchAssetsFor(type: value, imageList: nil)
            } else {
                try await prefetchAssetsFor(type: value, imageList: value.list.items)
            }
            
        case .typeScreenImageTitleSubtitleList(let value):

            try await prefetchAssetsFor(type: value, imageList: value.list.items)
        case .typeScreenTwoColumnMultipleSelection(let value):
            if CellConfigurator.isImageHiddenFor(itemType: value.list.itemType) {
                try await prefetchAssetsFor(type: value, imageList: nil)
            } else {
                try await prefetchAssetsFor(type: value, imageList: value.list.items)
            }
            
        case .typeScreenTwoColumnSingleSelection(let value):
            
            if CellConfigurator.isImageHiddenFor(itemType: value.list.itemType) {
                try await prefetchAssetsFor(type: value, imageList: nil)
            } else {
                try await prefetchAssetsFor(type: value, imageList: value.list.items)
            }
            
        case .typeScreenImageTitleSubtitleMultipleSelectionList(let value):
            if await ImageLabelCollectionCell.isImageHiddenFor(itemType: value.list.itemType) {
                try await prefetchAssetsFor(type: value, imageList: nil)
            } else {
                try await prefetchAssetsFor(type: value, imageList: value.list.items)
            }
            
        case .typeScreenSlider(let value):
            
            let imageList = value.slider.items.compactMap({$0.content})
            try await prefetchAssetsFor(type: value, imageList: imageList)
        case .typeScreenTitleSubtitlePicker(let value):
            
            try await prefetchAssetsFor(type: value, imageList: nil)
        }
    }
    
    func prefetchAssetsFor(type: Any, imageList: Any?) async throws {
        var allAssets = [AssetPrefetchType]()
        let useLocalAssetsIfAvailable: Bool = (type as? BaseScreenProtocol)?.useLocalAssetsIfAvailable ?? true
        if let screenDataType = type as? ImageProtocol {
            let image: [AssetPrefetchType] = [.from(image: screenDataType.image, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)].compactMap({ $0 })
            allAssets += image
        }
        if let screenDataType = type as? ImageOptionalProtocol, let image =  screenDataType.image {
            let image: [AssetPrefetchType] = [.from(image: image, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)].compactMap({ $0 })
            allAssets += image
        }
        if let screenDataType = type as? BaseScreenStyleProtocol {
            let backgroundAssets = assetsFor(backgroundStyle: screenDataType.styles.background, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            allAssets += backgroundAssets
        }
        
        if let screenDataType = type as? PaywallBaseScreenStyleProtocol {
            let useLocalAssetsIfAvailableForPaywall = screenDataType.useLocalAssetsIfAvailable
            let backgroundAssets = assetsFor(backgroundStyle: screenDataType.styles.background, useLocalAssetsIfAvailable: useLocalAssetsIfAvailableForPaywall)
            let mediaAssets = assetsFor(media: screenDataType.media, useLocalAssetsIfAvailable: useLocalAssetsIfAvailableForPaywall)
            
            allAssets += backgroundAssets
            allAssets += mediaAssets

        }
        
        if let screenDataType = type as? MediaProtocol {
            let useLocalAssetsIfAvailableForPaywall = screenDataType.useLocalAssetsIfAvailable
            let mediaAssets = assetsFor(media: screenDataType.media, useLocalAssetsIfAvailable: useLocalAssetsIfAvailableForPaywall)
            
            allAssets += mediaAssets
        }
        
        let listAsset = prefetchAssetsFor(list: imageList, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
        allAssets += listAsset
        
        try await load(assets: allAssets)
    }
    
    func prefetchAssetsFor(list: Any?, useLocalAssetsIfAvailable: Bool) -> [AssetPrefetchType]  {
        if let imageList = list as? (any Sequence)  {
            let images = imageList.compactMap { item in
                if let image =  item as? ImageProtocol {
                    return image
                }
                return nil
            }
            
            let imageAssets = prefetchAssetsFor(type: images, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
            
            return imageAssets
        }
        return []
    }
    
    func prefetchAssetsFor(type: [ImageProtocol], useLocalAssetsIfAvailable: Bool) -> [AssetPrefetchType]  {
        let images = type.map({ $0.image })
        let imageAssets = images.compactMap({ AssetPrefetchType.from(image: $0, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable) })
        return imageAssets
    }
    
    func assetsFor(backgroundStyle: BackgroundStyle, useLocalAssetsIfAvailable: Bool) -> [AssetPrefetchType] {
        switch backgroundStyle.styles {
        case .typeBackgroundStyleColor:
            return []
        case .typeBackgroundStyleImage(let value):
            return [.from(baseImage: value.image, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)].compactMap({ $0 })
        case .typeBackgroundStyleVideo(let value):
            return [.from(baseVideo: value.video, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)].compactMap({ $0 })
        }
    }
    
    func assetsFor(media: Media?, useLocalAssetsIfAvailable: Bool) -> [AssetPrefetchType] {
        guard let media = media else { return [] }
        
        switch media.content {
        case .typeMediaImage(let value):
            return [.from(baseImage: value.image, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)].compactMap({ $0 })
        case .typeMediaVideo(let value):
            return [.from(baseVideo: value.video, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)].compactMap({ $0 })
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
            holder.finish(result: result)
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
    func load(asset: AssetPrefetchType) async throws  {
        switch asset {
        case .image(let assetProvider, let useLocalAssetsIfAvailable):
            if await assetProvider.loadImage(useLocalAssetsIfAvailable: useLocalAssetsIfAvailable) == nil {
                throw AssetsPrefetchError.imageLoadingError(.failedToLoadAsset)
            }
        case .video(let assetProvider, let useLocalAssetsIfAvailable):
            if await assetProvider.urlToVideoAsset(useLocalAssetsIfAvailable: useLocalAssetsIfAvailable) == nil {
                throw AssetsPrefetchError.imageLoadingError(.failedToLoadAsset)
            }
        }
    }
    
    func load(assets: [AssetPrefetchType]) async throws  {
        guard !assets.isEmpty else {
            return
        }
        
        var loadingErrors: [Error] = []
        
        await withTaskGroup(of: Error?.self) { taskGroup in
            for asset in assets {
                taskGroup.addTask {
                    do {
                        try await self.load(asset: asset)
                        return nil
                    } catch {
                        return error
                    }
                }
            }
            
            for await error in taskGroup {
                if let error {
                    loadingErrors.append(error)
                }
            }
        }
        if !loadingErrors.isEmpty {
            throw AssetLoadingError.failedToLoadAsset
        }
    }
}

// MARK: - Private methods
private extension AssetsPrefetchService {
    final class ResultCallbackHolder {
        let id: UUID = UUID()
        private var callback: AssetsPrefetchResultCallback?
        var task: Task<Void, Error>!
        
        init() {
            task = Task<Void, Error> { [weak self] in
                try await withCheckedThrowingContinuation { [weak self] continuation in
                    self?.callback = { result in
                        switch result {
                        case .success:
                            continuation.resume(returning: Void())
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
        
        func wait() async throws {
            try await task.value
        }
        
        func finish(result: AssetsPrefetchResult) {
            callback?(result)
        }
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

private enum AssetPrefetchType {
    case image(assetProvider: OnboardingLocalImageAssetProvider, useLocalAssetsIfAvailable: Bool)
    case video(assetProvider: OnboardingLocalVideoAssetProvider, useLocalAssetsIfAvailable: Bool)
    
    static func from(image: Image,
                     useLocalAssetsIfAvailable: Bool) -> AssetPrefetchType? {
        guard image.assetUrlByLocale() != nil else { return nil }
        return .image(assetProvider: image, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
    }
    
    static func from(baseImage: BaseImage,
                     useLocalAssetsIfAvailable: Bool) -> AssetPrefetchType? {
        guard baseImage.assetUrlByLocale() != nil else { return nil }
        return .image(assetProvider: baseImage, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
    }
    
    static func from(baseVideo: BaseVideo,
                     useLocalAssetsIfAvailable: Bool) -> AssetPrefetchType? {
        guard baseVideo.assetUrlByLocale() != nil else { return nil }
        return .video(assetProvider: baseVideo, useLocalAssetsIfAvailable: useLocalAssetsIfAvailable)
    }
}
