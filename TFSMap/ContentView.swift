//
//  ContentView.swift
//  TFSMap
//
//  Created by Tyler Wade on 11/13/24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var activeTabIndex = 2
    
    var body: some View {
        MapView()
            // This app only supports light mode
            // so make sure that is enforced.
            .colorScheme(.light)
    }
}

#Preview {
    ContentView()
}
