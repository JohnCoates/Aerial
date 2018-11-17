//
//  DownloadManager.swift
//  Aerial
//
//  Created by Guillaume Louel on 03/10/2018.
//  Copyright © 2018 John Coates. All rights reserved.

import Cocoa

/// Manager of asynchronous download `Operation` objects

final class DownloadManager: NSObject {

    /// Dictionary of operations, keyed by the `taskIdentifier` of the `URLSessionTask`

    fileprivate var operations = [Int: DownloadOperation]()

    /// Serial OperationQueue for downloads

    private let queue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "download"
        operationQueue.maxConcurrentOperationCount = 3
        return operationQueue
    }()

    /// Delegate-based `URLSession` for DownloadManager

    lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    /// Add download
    ///
    /// - parameter URL:  The URL of the file to be downloaded
    ///
    /// - returns:        The DownloadOperation of the operation that was queued

    @discardableResult
    func queueDownload(_ url: URL) -> DownloadOperation {
        let operation = DownloadOperation(session: session, url: url)
        operations[operation.task.taskIdentifier] = operation
        queue.addOperation(operation)
        return operation
    }

    /// Cancel all queued operations

    func cancelAll() {
        queue.cancelAllOperations()
    }

}

// MARK: URLSessionDownloadDelegate methods

extension DownloadManager: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        operations[downloadTask.taskIdentifier]?.urlSession(session,
                                                            downloadTask: downloadTask,
                                                            didFinishDownloadingTo: location)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        operations[downloadTask.taskIdentifier]?.urlSession(session,
                                                            downloadTask: downloadTask,
                                                            didWriteData: bytesWritten,
                                                            totalBytesWritten: totalBytesWritten,
                                                            totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
}

// MARK: URLSessionTaskDelegate methods

extension DownloadManager: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let key = task.taskIdentifier
        operations[key]?.urlSession(session, task: task, didCompleteWithError: error)
        operations.removeValue(forKey: key)
    }

}

/// Asynchronous Operation subclass for downloading

final class DownloadOperation: AsynchronousOperation {
    let task: URLSessionTask

    init(session: URLSession, url: URL) {
        task = session.downloadTask(with: url)
        super.init()
    }

    override func cancel() {
        task.cancel()
        super.cancel()
    }

    override func main() {
        task.resume()
    }
}

// MARK: NSURLSessionDownloadDelegate methods
//       Customized for our usage
extension DownloadOperation: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let manager = FileManager.default
            var destinationURL = URL(fileURLWithPath: VideoCache.cacheDirectory!)

            // tvOS11 and tvOS10 JSONs are named entries.json, so we rename them here
            if downloadTask.originalRequest!.url!.absoluteString.contains("2x/entries.json") {
                debugLog("Caching tvos11.json")
                destinationURL.appendPathComponent("tvos11.json")
            } else if downloadTask.originalRequest!.url!.absoluteString.contains("Autumn") {
                debugLog("Caching tvos10.json")
                destinationURL.appendPathComponent("tvos10.json")
            } else {
                debugLog("Caching \(downloadTask.originalRequest!.url!.lastPathComponent)")
                destinationURL.appendPathComponent(downloadTask.originalRequest!.url!.lastPathComponent)
            }

            try? manager.removeItem(at: destinationURL)
            try manager.moveItem(at: location, to: destinationURL)
        } catch {
            errorLog("\(error)")
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        //let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        //print("\(downloadTask.originalRequest!.url!.absoluteString) \(progress)")
    }
}

// MARK: URLSessionTaskDelegate methods

extension DownloadOperation: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer { finish() }

        if let error = error {
            errorLog("\(error)")
            return
        }

        // We need to untar the resources.tar
        if task.originalRequest!.url!.absoluteString.contains("resources.tar") {
            debugLog("untaring resources.tar")

            // Extract json
            let process: Process = Process()
            let cacheDirectory = VideoCache.cacheDirectory!

            var cacheResourcesString = cacheDirectory
            cacheResourcesString.append(contentsOf: "/resources.tar")

            process.currentDirectoryPath = cacheDirectory
            process.launchPath = "/usr/bin/tar"
            process.arguments = ["-xvf", cacheResourcesString]

            process.launch()

            process.waitUntilExit()
        }

        debugLog("Finished downloading \(task.originalRequest!.url!.absoluteString)")
    }
}
