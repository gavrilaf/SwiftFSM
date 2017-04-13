//
//  FSMSimpleLogger.swift
//  SwiftFSM
//
//  Created by Eugen Fedchenko on 4/11/17.
//  Copyright © 2017 Personal. All rights reserved.
//

import Foundation

struct FSMSimpleLogger: FSMLogger {
    func debugLog(_ s: String) {
        print("FSMLogger: \(s)")
    }
}
