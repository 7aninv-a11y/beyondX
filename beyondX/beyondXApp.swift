//
//  beyondXApp.swift
//  beyondX
//
//  Created by Hanin on 11/05/1448 AH.
//

import SwiftUI

@main
struct beyondXApp: App {

    // NEW: أول ما يفتح التطبيق نصفّر كل شي (النجوم + الأفكار + الإجابات)
    init() {
        GameStorage.resetAll()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
