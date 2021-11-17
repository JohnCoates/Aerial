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
    ///          folder:  The name of the subfolder where the file will be stored
    ///
    /// - returns:        The DownloadOperation of the operation that was queued

    @discardableResult
    func queueDownload(_ url: URL, folder: String) -> DownloadOperation {
        let operation = DownloadOperation(session: session, url: url, folder: folder)
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
    let folder: String

    init(session: URLSession, url: URL, folder: String) {
        self.folder = folder
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
    // This is where we save the file to its location
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            // We may need to create our destination
            let destinationDirectory = Cache.supportPath.appending("/" + folder)
            FileHelpers.createDirectory(atPath: destinationDirectory)

            let manager = FileManager.default
            let supportURL = URL(fileURLWithPath: Cache.supportPath.appending("/" + folder))

            debugLog("Caching \(downloadTask.originalRequest!.url!.lastPathComponent) at \(folder)")

            // The file may exist, remove it
            try? manager.removeItem(at: supportURL.appendingPathComponent(
                                        downloadTask.originalRequest!.url!.lastPathComponent))

            // Finally move the file
            try manager.moveItem(at: location, to: supportURL.appendingPathComponent(
                                    downloadTask.originalRequest!.url!.lastPathComponent))
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
        // let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        // print("\(downloadTask.originalRequest!.url!.absoluteString) \(progress)")
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

        let destinationDirectory = Cache.supportPath.appending("/" + folder)

        // Some manifests come in tar form, in that case untar them here
        if folder == "tvOS 13" {
            FileHelpers.unTar(file: destinationDirectory.appending("/resources-13.tar"), atPath: destinationDirectory)
        } else if folder == "tvOS 15" {
            FileHelpers.unTar(file: destinationDirectory.appending("/resources-15.tar"), atPath: destinationDirectory)
        } else if folder == "tvOS 12" {
            FileHelpers.unTar(file: destinationDirectory.appending("/resources.tar"), atPath: destinationDirectory)
        }

        debugLog("Finished downloading \(task.originalRequest!.url!.absoluteString)")
    }
}
