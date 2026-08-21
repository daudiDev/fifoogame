//
//  AppManager.swift
//  fifoo
//
//  Created by Daudi Sagala on 6/1/26.
//

import Foundation
import SwiftUI
import Combine

final class AppManager: ObservableObject {
    
    static let shared = AppManager()
    @Published var selectedDate: Date = Date()
    
    private init() {}
    
}
