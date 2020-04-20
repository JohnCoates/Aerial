//
//  ConditionLayer.swift
//  Aerial
//
//  Created by Guillaume Louel on 17/04/2020.
//  Copyright © 2020 Guillaume Louel. All rights reserved.
//

import Foundation
import AVKit

class ConditionLayer: CALayer {
    init(condition: Weather.Condition) {
        super.init()

        frame.size = CGSize(width: 200, height: 75)
        print(condition)

        let temp = CATextLayer()
        temp.string = "\(condition.temperature)°"
        temp.frame.size = CGSize(width: 100, height: 75)
        (temp.font, temp.fontSize) = temp.makeFont(name: PrefsInfo.weather.fontName, size: PrefsInfo.weather.fontSize)

        // ReRect the temperature
        let rect = temp.calculateRect(string: temp.string as! String, font: temp.font as! NSFont)
        addSublayer(temp)

        // We put the temperature at the right of the weather icon
        temp.anchorPoint = CGPoint(x: 0, y: 1)
        temp.position = CGPoint(x: 100, y: 65)
        //temp.backgroundColor = .black

        frame.size = CGSize(width: 100 + rect.size.width, height: 75)

        downloadImage(from: URL(string: "https://s.yimg.com/zz/combo?a/i/us/nws/weather/gr/\(condition.code)d.png")!)
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    func downloadImage(from url: URL) {
        print("Download Started")
        getData(from: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() {
                let imgs = NSImage(data: data)
                if let img = imgs {
                    let imglayer = CALayer()

                    imglayer.frame.size.height = img.size.height / 2
                    imglayer.frame.size.width = img.size.width / 2
                    imglayer.contents = img
                    //imglayer.backgroundColor = .white
                    imglayer.anchorPoint = CGPoint(x: 0, y: 1)
                    imglayer.position = CGPoint(x: 0, y: 75)
                    self.addSublayer(imglayer)
                }
            }
        }
    }
}
