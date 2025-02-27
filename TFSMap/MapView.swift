//
//  MapView.swift
//  TFSMap
//
//  Created by Tyler Wade on 11/13/24.
//

import SwiftUI
import TransformGesture
import simd
import SVGView

class Room {
    public let name: String
    
    init(named name: String) {
        self.name = name
    }
}

class Floor {
    
    public let svgNode: SVGNode
    public let rooms:[Room] = []
    
    init(svgNode: SVGNode) {
        self.svgNode = svgNode
    }
}

class Building {
    
    public let name: String
    public let roofNode: SVGNode
    public let hitRect: CGRect
    public var floors:[Floor] = []
    
    init(named name: String, roofNode: SVGNode, hitRect: CGRect) {
        self.name = name
        self.roofNode = roofNode
        self.hitRect = hitRect
    }
}

struct MapView: View {
    
    // Coordinate spaces
    //
    // Map Space:
    //   A coordinate that is relative to the map.
    //   The coordinates go from (0, 0) at the
    //   top-left and extend out to svgSize.
    //
    // Screen Space:
    //   A coordinate that is relative to the screen.
    //   The coordinates go from (0, 0) at the
    //   top-left and and go to viewSize
    //

    // The zoom scale at which the text on the buildings apear
    private static let textAppearScale = 7.0
    
    private static let svgSize: CGSize = CGSize(width: 1000, height: 700)
    
    // This stores the current transform data for the map
    @StateObject private var transform = TouchTransform(
        translation: CGSize(width: 100, height: 190),
        scale: 3,
        scaleRange: 3...30,
        rotationRange: 0...0)
    
    // The size that this view is being drawn at
    @State private var viewSize: CGSize = .zero
    
    // The size of the actaual SVG view that gets rendered
    @State private var svgView: SVGView
    
    @State private var svgDisplayScale: CGFloat = 0
    @State private var svgDisplaySize: CGSize = .zero
    
    // When a building is active, its roof is hidden
    // revealing the interior. Only one building
    // can be active at a time.
    @State private var activeBuilding: Building? = nil
    
    private var buildings:[Building] = []
    
    init() {
        
        // Load the SVG view
        let svgURL = Bundle.main.url(forResource: "TandemMap", withExtension: "svg")!
        self.svgView = SVGView(contentsOf: svgURL)
        
        var mainBldg = Building(named: "Main Building",
            roofNode: getNode(named: "Main_Roof"),
            hitRect: getRect(named: "Main_HitBox"));
        
        var mainBldg_F1 = Floor(svgNode: getNode(named: "Main_F1"))
        var mainBldg_F2 = Floor(svgNode: getNode(named: "Main_F2"))
        mainBldg.floors.append(mainBldg_F1)
        mainBldg.floors.append(mainBldg_F2)
        mainBldg_F1.svgNode.opacity = 0
        mainBldg_F2.svgNode.opacity = 0
        
        var communityBldg = Building(named: "Community Hall",
            roofNode: getNode(named: "Community_Roof"),
            hitRect: getRect(named: "Community_HitBox"))
        
        var communityBldg_F1 = Floor(svgNode: getNode(named: "Community_F1"))
        var communityBldg_F2 = Floor(svgNode: getNode(named: "Community_F2"))
        communityBldg.floors.append(communityBldg_F1)
        communityBldg.floors.append(communityBldg_F2)
        communityBldg_F1.svgNode.opacity = 0
        communityBldg_F2.svgNode.opacity = 0
        
        var artBldg = Building(named: "Arts Annex",
            roofNode: getNode(named: "Art_Roof"),
            hitRect: getRect(named: "Art_HitBox"))
        
        var artBldg_F1 = Floor(svgNode: getNode(named: "Art_F1"))
        artBldg.floors.append(artBldg_F1)
        artBldg_F1.svgNode.opacity = 0
        
        var musicBldg = Building(named: "Music",
            roofNode: getNode(named: "Music_Roof"),
            hitRect: getRect(named: "Music_HitBox"))
        
        var musicBldg_F1 = Floor(svgNode: getNode(named: "Music_F1"))
        musicBldg.floors.append(musicBldg_F1)
        musicBldg_F1.svgNode.opacity = 0
        
        var middleBldg = Building(named: "Middle School",
            roofNode: getNode(named: "Middle_Roof"),
            hitRect: getRect(named: "Middle_HitBox"))
        
        var middleBldg_F1 = Floor(svgNode: getNode(named: "Middle_F1"))
        var middleBldg_F2 = Floor(svgNode: getNode(named: "Middle_F2"))
        middleBldg.floors.append(middleBldg_F1)
        middleBldg.floors.append(middleBldg_F2)
        middleBldg_F1.svgNode.opacity = 0
        middleBldg_F2.svgNode.opacity = 0
        
        var mathBldg = Building(named: "Math/Science Building",
            roofNode: getNode(named: "Math_Roof"),
            hitRect: getRect(named: "Math_HitBox"))
        
        var mathBldg_F1 = Floor(svgNode: getNode(named: "Math_F1"))
        var mathBldg_F2 = Floor(svgNode: getNode(named: "Math_F2"))
        mathBldg.floors.append(mathBldg_F1)
        mathBldg.floors.append(mathBldg_F2)
        mathBldg_F1.svgNode.opacity = 0
        mathBldg_F2.svgNode.opacity = 0
        
        var pavilionBldg = Building(named: "Pavilion",
            roofNode: getNode(named: "Pavilion_Roof"),
            hitRect: getRect(named: "Pavilion_HitBox"))
        
        var pavilionBldg_F1 = Floor(svgNode: getNode(named: "Pavilion_F1"))
        pavilionBldg.floors.append(pavilionBldg_F1)
        pavilionBldg_F1.svgNode.opacity = 0
        
        var gymBldg = Building(named: "Field House/Gym",
            roofNode: getNode(named: "Gym_Roof"),
            hitRect: getRect(named: "Gym_HitBox"))
        
        var gymBldg_F1 = Floor(svgNode: getNode(named: "Gym_F1"))
        gymBldg.floors.append(gymBldg_F1)
        gymBldg_F1.svgNode.opacity = 0
        
        buildings.append(mainBldg)
        buildings.append(communityBldg)
        buildings.append(artBldg)
        buildings.append(musicBldg)
        buildings.append(middleBldg)
        buildings.append(mathBldg)
        buildings.append(pavilionBldg)
        buildings.append(gymBldg)
        
        getNode(named: "Main_HitBox").opacity = 0
        getNode(named: "Community_HitBox").opacity = 0
        getNode(named: "Art_HitBox").opacity = 0
        getNode(named: "Math_HitBox").opacity = 0
        getNode(named: "Music_HitBox").opacity = 0
        getNode(named: "Middle_HitBox").opacity = 0
        getNode(named: "Gym_HitBox").opacity = 0
        getNode(named: "Pavilion_HitBox").opacity = 0
    }
    
    func getNode(named name: String) -> SVGNode {
        return svgView.getNode(byId: name)!
    }
    
    func getRect(named name: String) -> CGRect {
        return svgRectToCGRect(getNode(named: name) as! SVGRect)
    }
    
    func svgRectToCGRect(_ svgRect: SVGRect) -> CGRect {
        return CGRect(
            x: svgRect.x,
            y: svgRect.y,
            width: svgRect.width,
            height: svgRect.height)
    }
    
    // Transforms a point from screen space to map space
    func ScreenToMapSpace(_ point: CGPoint) -> CGPoint {
        var trPoint = transform
            .matrixInveresed
            .transformed2D(point.simd_float2)
        
        let size = svgDisplaySize
        let scale = svgDisplayScale
        
        return CGPoint(
            x: (CGFloat(trPoint.x) + size.width / 2) / scale,
            y: (CGFloat(trPoint.y) + size.height / 2) / scale)
    }
    
    // Transforms a point from map space to screen space
    func MapToScreenSpace(_ mapPoint: CGPoint) -> CGPoint {
        
        let size = svgDisplaySize
        let scale = svgDisplayScale
        
        let aPoint = CGPoint(x: mapPoint.x * scale - size.width / 2, y: mapPoint.y * scale - size.height / 2)
        
        let trPoint = transform
            .matrix
            .transformed2D(aPoint.simd_float2)
        
        return CGPoint(
            x: CGFloat(trPoint.x),
            y: CGFloat(trPoint.y))
    }
    
    // Gets the building that contains mapPoint
    private func getBuilding(at mapPoint: CGPoint) -> Building? {
        for building in buildings {
            if building.hitRect.contains(mapPoint) {
                return building
            }
        }
        return nil
    }
    
    // Called whenever the user taps on the map
    func onTapped(screenPoint: CGPoint) {
        
        // Find the point on the map that the user tapped on
        var mapPoint = ScreenToMapSpace(screenPoint)
        
        // Check if this point is conateined within a building
        let tappedBuilding = getBuilding(at: mapPoint)
        
        // Only do something if the building that was tapped
        // is not the same one that is already active
        if activeBuilding !== tappedBuilding {
            
            // Show the roof of the building that was previously active
            if activeBuilding !== nil {
                activeBuilding!.roofNode.opacity = 1
                activeBuilding!.floors[0].svgNode.opacity = 0
            }
            
            activeBuilding = tappedBuilding
            
            // Hide the roof that is now currently active
            if tappedBuilding !== nil {
                tappedBuilding!.roofNode.opacity = 0
                tappedBuilding!.floors[0].svgNode.opacity = 1
            }
        }
        
    }
    
    func computeTextOpacity() -> CGFloat {
        return 1.0
//        return transform.scale >= Self.textAppearScale ? 1.0 : 0.0
    }
    
    func drawText(_ context: inout GraphicsContext, _ string: String, _ point: CGPoint) {
        var textPos = CGPoint(x: point.x, y: point.y)
        
        let font = Font.system(size: 16)
        
        let textOpacity = computeTextOpacity()
        
        let shadowText = Text(string)
            .font(font)
            .foregroundStyle(Color(hue: 0, saturation: 0, brightness: 0.3).opacity(textOpacity))
        let shadowTextPos = CGPoint(x: point.x + 1, y: point.y + 1)
        context.draw(context.resolve(shadowText), at: shadowTextPos, anchor: .center)
        
        let text = Text(string)
            .font(font)
            .foregroundStyle(.white.opacity(textOpacity))
        context.draw(context.resolve(text), at: point, anchor: .center)
    }
    
    var body: some View {
        ZStack {
            Color("MapBackground", bundle: Bundle.main)
                .ignoresSafeArea()
            
            ZStack {
                
                // This is the actual SVG that is being rendered
                svgView
                    .transformEffect(transform)
                    .background(GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                DispatchQueue.main.async {
                                    viewSize = geometry.size
                                    //geometry.safeAreaRegions
                                    
                                    // Calculate the size at which the SVG is being rendered at
                                    // without any transformations applied (pan/zoom)
                                    svgDisplayScale = viewSize.width / Self.svgSize.width
                                    svgDisplaySize = CGSize(
                                        width: Self.svgSize.width * svgDisplayScale,
                                        height: Self.svgSize.height * svgDisplayScale)
                                }
                            }
                    })

                // Draw the names of the buildings ontop with a canvas
                Canvas { context, _ in
                    
                    for building in buildings {
                        
                        if building === activeBuilding {
                            continue
                        }
                        
                        let mapPoint = CGPoint(
                            x: building.hitRect.midX,
                            y: building.hitRect.midY)
                        
                        let screenPoint = MapToScreenSpace(mapPoint)
                        
                        drawText(&context, building.name, screenPoint)
                    }
                }
            }
            
            if activeBuilding !== nil {
                VStack {
                    RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                        .fill(Color.white)
                        .frame(width: 300, height: 80)
                        .overlay {
                            Text(activeBuilding!.name)
                                .font(.system(size: 20, weight: .bold))
                        }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .transformGesture(transform: transform, draggingDisabled: true, onTap: onTapped)
    }
}

#Preview {
    MapView()
}
