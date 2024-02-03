//
//  File.swift
//  
//
//  Created by Oleg Kuplin on 02.02.2024.
//

import Foundation
import ScreensGraph

final class TestsFilesHolder {
    
    static let shared = TestsFilesHolder()
   
    private var cache: [String: URL] = [:] // Save all local files in this cache
    private let baseURL = urlForRestServicesTestsDir()
    
    init() {
        guard let enumerator = FileManager.default.enumerator(
            at: baseURL,
            includingPropertiesForKeys: [.nameKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: nil) else {
            fatalError("Could not enumerate \(baseURL)")
        }
        
        for case let url as URL in enumerator where url.isFileURL {
            cache[url.lastPathComponent] = url
        }
    }
    
    func url(for fileName: String) -> URL? {
        return cache[fileName]
    }
    
    func loadScreenGraph() throws -> ScreensGraph {
        let jsonName = "onboarding-tests.json"
        let localPath = url(for: jsonName)!
        let data = try Data(contentsOf: localPath)
        let decoder = JSONDecoder()
        let screenGraph = try decoder.decode(ScreensGraph.self, from: data)
        return screenGraph
    }
    
    private static func urlForRestServicesTestsDir() -> URL {
        let currentFileURL = URL(fileURLWithPath: "\(#file)", isDirectory: false)
        return currentFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    
}
