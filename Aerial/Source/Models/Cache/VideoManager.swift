//
//  VideoManager.swift
//  Aerial
//
//  Created by Guillaume Louel on 08/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.
//

import Foundation

class VideoManager : NSObject {
    static let sharedInstance = VideoManager()

    /// Dictionary of CheckCellView, keyed by the video.id
    private var checkCells = [String: CheckCellView]()
    
    /// List of queued videos, by video.id
    private var queuedVideos = [String]()
    
    /// Dictionary of operations, keyed by the video.id
    fileprivate var operations = [String: VideoDownloadOperation]()

    //var downloadItems: [VideoDownloadItem]
    /// Serial OperationQueue for downloads
    
    private let queue: OperationQueue = {
        let _queue = OperationQueue()
        _queue.name = "videodownload"
        _queue.maxConcurrentOperationCount = 1
        
        return _queue
    }()
    
    // MARK: Tracking CheckCellView
    func addCheckCellView(id: String, checkCellView: CheckCellView) {
        checkCells[id] = checkCellView
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
        
        let operation = VideoDownloadOperation(video:video, delegate: self)
        operations[video.id] = operation
        queue.addOperation(operation)

        queuedVideos.append(video.id)       // Our Internal List of queued videos
        markAsQueued(id: video.id)          // Callback the CheckCellView

        return operation
    }
    
    // Callbacks for Items
    func finishedDownload(id: String)
    {
        // Manage our queuedVideo index
        if let index = queuedVideos.firstIndex(of: id) {
            queuedVideos.remove(at: index)
        }
        
        // Then callback the CheckCellView
        if let cell = checkCells[id] {
            cell.markAsDownloaded()
        }
    }
    
    func markAsQueued(id:String) {
        // Manage our queuedVideo index
        if let cell = checkCells[id] {
            cell.markAsQueued()
        }
    }
    func updateProgress(id: String, progress: Double) {
        if let cell = checkCells[id] {
            cell.updateProgressIndicator(progress: progress)
        }
    }
}



class VideoDownloadOperation : AsynchronousOperation {
    var video: AerialVideo
    var download: VideoDownload?
    
    init(video: AerialVideo, delegate: VideoManager) {
        debugLog("Video queued \(video.name)")
        self.video = video
    }
    
    override func main() {
        print("start \(video.name)")
        DispatchQueue.main.async {
            self.download = VideoDownload(video: self.video, delegate: self)
            self.download!.startDownload()
        }
    }
}

extension VideoDownloadOperation : VideoDownloadDelegate {
    func videoDownload(_ videoDownload: VideoDownload,
                       finished success: Bool, errorMessage: String?) {
        print("finished")
        defer { finish() }

        // Call up to clean the view
        let videoManager = VideoManager.sharedInstance
        videoManager.finishedDownload(id: videoDownload.video.id)
    }
    
    func videoDownload(_ videoDownload: VideoDownload, receivedBytes: Int, progress: Float) {
        // Call up to update the view
        let videoManager = VideoManager.sharedInstance
        videoManager.updateProgress(id: videoDownload.video.id, progress: Double(progress))
    }
}
