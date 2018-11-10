//
//  PreferencesTests
//  Aerial Tests
//
//  Created by John Coates on 9/22/16.
//  Copyright © 2016 John Coates. All rights reserved.
//

import XCTest
@testable import AerialApp

class PreferencesTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testPreferenceSaving() {
        let preferences = Preferences.sharedInstance
        preferences.cacheAerials = false

        let newPreferences = Preferences()
        XCTAssertFalse(newPreferences.cacheAerials, "Property write verified")
    }
}
