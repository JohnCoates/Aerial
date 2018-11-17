//
//  VideoManager.swift
//  Aerial
//
//  Created by Guillaume Louel on 08/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.
//

import Foundation
typealias VideoManagerCallback = (Int, Int) -> Void
typealias VideoProgressCallback = (Int, Int, Double) -> Void

final class VideoManager: NSObject {
    static let sharedInstance = VideoManager()
    var managerCallbacks = [VideoManagerCallback]()
    var progressCallbacks = [VideoProgressCallback]()

    /// Dictionary of CheckCellView, keyed by the video.id
    private var checkCells = [String: CheckCellView]()

    /// List of queued videos, by video.id
    private var queuedVideos = [String]()

    /// Dictionary of operations, keyed by the video.id
    fileprivate var operations = [String: VideoDownloadOperation]()

    /// Number of videos that were queued
    private var totalQueued = 0
    var stopAll = false

    //var downloadItems: [VideoDownloadItem]
    /// Serial OperationQueue for downloads

    private let queue: OperationQueue = {
        // swiftlint:disable:next identifier_name
        let _queue = OperationQueue()
        _queue.name = "videodownload"
        _queue.maxConcurrentOperationCount = 1

        return _queue
    }()

    // MARK: Tracking CheckCellView
    func addCheckCellView(id: String, checkCellView: CheckCellView) {
        checkCells[id] = checkCellView
    }

    func addCallback(_ callback:@escaping VideoManagerCallback) {
        managerCallbacks.append(callback)
    }

    func addProgressCallback(_ callback:@escaping VideoProgressCallback) {
        progressCallbacks.append(callback)
    }

    // Is the video queued for download ?
    func isVideoQueued(id: String) -> Bool {
        if queuedVideos.firstIndex(of: id) != nil {
            return true
        } else {
            return false
        }
    }

    @discardableResult
    func queueDownload(_ video: AerialVideo) -> VideoDownloadOperation {
        print(queue.isSuspended)
        if stopAll {
            stopAll = false
        }

        print(queue.operations)

        let operation = VideoDownloadOperation(video: video, delegate: self)
        operations[video.id] = operation
        queue.addOperation(operation)

        queuedVideos.append(video.id)       // Our Internal List of queued videos
        markAsQueued(id: video.id)          // Callback the CheckCellView
        totalQueued += 1                    // Increment our count

        DispatchQueue.main.async {
            // Callback the callbacks
            for callback in self.managerCallbacks {
                callback(self.totalQueued-self.queuedVideos.count, self.totalQueued)
            }
        }
        return operation
    }

    // Callbacks for Items
    func finishedDownload(id: String, success: Bool) {
        // Manage our queuedVideo index
        if let index = queuedVideos.firstIndex(of: id) {
            queuedVideos.remove(at: index)
        }

        if queuedVideos.isEmpty {
            totalQueued = 0
        }

        DispatchQueue.main.async {
            // Callback the callbacks
            for callback in self.managerCallbacks {
                callback(self.totalQueued-self.queuedVideos.count, self.totalQueued)
            }
        }
        // Then callback the CheckCellView
        if let cell = checkCells[id] {
            if success {
                cell.markAsDownloaded()
            } else {
                cell.markAsNotDownloaded()
            }
        }
    }

    func markAsQueued(id: String) {
        // Manage our queuedVideo index
        if let cell = checkCells[id] {
            cell.markAsQueued()
        }
    }
    func updateProgress(id: String, progress: Double) {
        if let cell = checkCells[id] {
            cell.updateProgressIndicator(progress: progress)
        }
        DispatchQueue.main.async {
            // Callback the callbacks
            for callback in self.progressCallbacks {
                callback(self.totalQueued-self.queuedVideos.count, self.totalQueued, progress)
            }
        }
    }

    /// Cancel all queued operations

    func cancelAll() {
        stopAll = true
        queue.cancelAllOperations()
    }
}

final class VideoDownloadOperation: AsynchronousOperation {
    var video: AerialVideo
    var download: VideoDownload?

    init(video: AerialVideo, delegate: VideoManager) {
        debugLog("Video queued \(video.name)")
        self.video = video
    }

    override func main() {
        let videoManager = VideoManager.sharedInstance
        if videoManager.stopAll {
            print("was cancelled and mained")
            return
        }

        debugLog("Starting download for \(video.name)")
        DispatchQueue.main.async {
            self.download = VideoDownload(video: self.video, delegate: self)
            self.download!.startDownload()
        }
    }

    override func cancel() {
        defer { finish() }
        let videoManager = VideoManager.sharedInstance

        if let _ = self.download {
            self.download!.cancel()
        } else {
            videoManager.finishedDownload(id: self.video.id, success: false)
        }
        self.download = nil
        super.cancel()
        //finish()
    }
}

extension VideoDownloadOperation: VideoDownloadDelegate {
    func videoDownload(_ videoDownload: VideoDownload,
                       finished success: Bool, errorMessage: String?) {
        debugLog("Finished")
        defer { finish() }

        let videoManager = VideoManager.sharedInstance
        if success {
            // Call up to clean the view
            videoManager.finishedDownload(id: videoDownload.video.id, success: true)
        } else {
            if let _ = errorMessage {
                errorLog(errorMessage!)
            }

            videoManager.finishedDownload(id: videoDownload.video.id, success: false)
        }
    }

    func videoDownload(_ videoDownload: VideoDownload, receivedBytes: Int, progress: Float) {
        // Call up to update the view
        let videoManager = VideoManager.sharedInstance
        videoManager.updateProgress(id: videoDownload.video.id, progress: Double(progress))
    }
}
