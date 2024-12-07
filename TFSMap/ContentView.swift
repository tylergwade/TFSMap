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
    }
}

//VStack {
//    Text("TFS Map")
//        .font(.system(size: 100))
//        .frame(width: .infinity, height: 700, alignment: .top)
//    
//}

#Preview {
    ContentView()
}
