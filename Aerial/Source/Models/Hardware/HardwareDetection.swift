//
//  HardwareDetection.swift
//  Aerial
//
//  Created by Guillaume Louel on 03/06/2019.
//  Copyright © 2019 John Coates. All rights reserved.
//

// When available, macOS will use the fixed functions units in Intel CPUs (QuickSync) for hardware
// decoding of H.264 and H.265, independent of if there's a GPU present.
// This is an issue as H.265 decoding is only partially supported on some Intel CPUs, up to Kaby Lake
// generation where they support Main profile decoding, but not Main10 (which is used by Apple's videos).
//
// Mode info can be found here : https://github.com/JohnCoates/Aerial/blob/master/Documentation/HardwareDecoding.md

import Foundation

enum HEVCMain10Support: Int {
    case notsupported, unsure, partial, supported
}

final class HardwareDetection: NSObject {
    static let sharedInstance = HardwareDetection()

    // MARK: - Mac Model detection

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

    // Get best suggestion
    // swiftlint:disable:next cyclomatic_complexity
    func getSuggestedFormat() -> VideoFormat {
        switch isHEVCMain10HWDecodingAvailable() {
        case .supported:
            if #available(OSX 10.15, *) {
                return .v4KHDR
            } else {
                // That was a fun one to track...
                return .v4KHEVC
            }
        case .notsupported:
            return .v1080pH264
        case .partial:
            // This is tricky
            let macModel = getMacModel()

            if macModel.starts(with: "iMac") {
                // iMacs, as far as we know, partial 17+, full 18+
                let ver = extractMacVersion(macModel: macModel, macSubmodel: "iMac")
                if ver >= 17.0 {
                    return .v4KHEVC
                } else {
                    return .v1080pH264
                }
            } else if macModel.starts(with: "MacBookPro") {
                let ver = extractMacVersion(macModel: macModel, macSubmodel: "MacBookPro")
                // MacBookPro full 14+
                if ver >= 17.0 {
                    return .v1080pHEVC
                } else {
                    return .v1080pH264
                }
            } else if macModel.starts(with: "MacBookAir") {
                // Retina 8+, I *think* they handle main10
                return .v1080pH264
            } else if macModel.starts(with: "MacBook") {
                // MacBook 10+
                return .v1080pH264
            }

            return .v1080pH264
        case .unsure:
            // Eh
            return .v1080pH264
        }
    }

    // MARK: - HEVC Main10 detection

    func isHEVCMain10HWDecodingAvailable() -> HEVCMain10Support {
        let macModel = getMacModel()

        // This is a manually compiled list based on CPU generations of each mac model line

        if macModel.starts(with: "iMacPro") || macModel.starts(with: "ADP") {
            // iMacPro - always
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
            // Tentative, I *think* 7+ (2019 MacPro) should always support independant of GPU, akin to iMac Pro ?
            return getHEVCMain10Support(macModel: macModel, macSubmodel: "MacPro", partial: 7.0, full: 7.0)
        }

        // Older stuff (power/etc) should not even run, so list should be complete
        // Hackintosh/new SKUs will fail this test, this is indicative in any case so that's fine
        return .unsure
    }

    // Helper
    private func getHEVCMain10Support(macModel: String, macSubmodel: String, partial: Double, full: Double) -> HEVCMain10Support {
        let ver = extractMacVersion(macModel: macModel, macSubmodel: macSubmodel)

        if ver >= full {
            return .supported
        } else if ver >= partial {
            return .partial
        } else {
            return .notsupported
        }
    }

}
