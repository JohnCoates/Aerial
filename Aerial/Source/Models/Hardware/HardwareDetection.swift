//
//  HardwareDetection.swift
//  Aerial
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

import Foundation

enum HEVCMain10Support: Int {
    case notsupported, unsure, partial, supported
}

final class HardwareDetection: NSObject {
    static let sharedInstance = HardwareDetection()

    // MARK: - Mac Model detection and HEVC Main10 detection
    private func getMacModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }

    private func extractMacVersion(macModel: String, macSubmodel: String) -> Double {
        // Substring the thing
        let str = String(macModel.dropFirst(macSubmodel.count))
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.number(from: str)?.doubleValue ?? 0.0
    }

    private func getHEVCMain10Support(macModel: String, macSubmodel: String, partial: Double, full: Double) -> HEVCMain10Support {
        let ver = extractMacVersion(macModel: macModel, macSubmodel: macSubmodel)

        if ver > full {
            return .supported
        } else if ver > partial {
            return .partial
        } else {
            return .notsupported
        }
    }

    func isHEVCMain10HWDecodingAvailable() -> HEVCMain10Support {
        let macModel = getMacModel()

        // iMacPro - always
        if macModel.starts(with: "iMacPro") {
            return .supported
        } else if macModel.starts(with: "iMac") {
            // iMacs, as far as we know, partial 17+, full 18+
            return getHEVCMain10Support(macModel: macModel, macSubmodel: "iMac", partial: 17.0, full: 18.0)
        } else if macModel.starts(with: "MacBookPro") {
            // MacBookPro full 14+
            return getHEVCMain10Support(macModel: macModel, macSubmodel: "MacBookPro", partial: 13.0, full: 14.0)
        } else if macModel.starts(with: "MacBookAir") {
            // Retina 8+, I *think* they handle main10
            return getHEVCMain10Support(macModel: macModel, macSubmodel: "MacBookAir", partial: 8.0, full: 8.0)
        } else if macModel.starts(with: "MacBook") {
            // MacBook 10+
            return getHEVCMain10Support(macModel: macModel, macSubmodel: "MacBook", partial: 9.0, full: 10.0)
        } else if macModel.starts(with: "Macmini") {
            // MacMini 8+
            return getHEVCMain10Support(macModel: macModel, macSubmodel: "Macmini", partial: 8.0, full: 8.0)
        } else if macModel.starts(with: "MacPro") {
            // Right now no support on these
            return .notsupported
        }
        // Older stuff (power/etc) should not even run this so list should be complete
        // Hackintosh/new SKUs will fail this test, this is indicative in any case so that's fine
        return .unsure
    }
}
