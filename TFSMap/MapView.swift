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
    public let floors:[Floor] = []
    
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
//    @StateObject private var transform = TouchTransform(
//        translation: CGSize(width: 100, height: 190),
//        scale: 3,
//        scaleRange: 3...30,
//        rotationRange: 0...0)
    
    @StateObject private var transform = TouchTransform(
        rotationRange: 0...0)
    
    // The size that this view is being drawn at
    @State private var viewSize: CGSize = .zero
    
    // The actaual SVG view that gets rendered
    @State private var svgView: SVGView
    
    // Hit detection test
    @State private var redHitBox: SVGRect? = nil // Make it optional for safety
    @State private var redRect: CGRect = .zero
    @State private var hitPoint: CGPoint = .zero
    @State private var isHitBoxTapped: Bool = false // Track tap state
    
    @State private var svgDisplayScale: CGFloat = 0
    @State private var svgDisplaySize: CGSize = .zero
    
    // The building that is currently selected
    // When a building is selected, its roof is hidden
    // revealing the interior.
    @State private var selectedBuilding: Building? = nil
    
    private var buildings:[Building] = []
    
    init() {
        
        // Load the SVG view
        let svgURL = Bundle.main.url(forResource: "TandemMap", withExtension: "svg")!
        self.svgView = SVGView(contentsOf: svgURL)
        
        buildings.append(
            Building(
                named: "Main Building",
                roofNode: getNode(named: "Main_Roof"),
                hitRect: getRect(named: "Main_HitBox")))
        
        buildings.append(
            Building(
                named: "Community Hall",
                roofNode: getNode(named: "Community_Roof"),
                hitRect: getRect(named: "Community_HitBox")))
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
    
    private func updateHitBoxColor() {
        if let redHitBox = redHitBox {
            redHitBox.fill = isHitBoxTapped
                ? SVGColor(r: 0, g: 255, b: 0) // Green when tapped
                : SVGColor(r: 20, g: 40, b: 240) // Blue when untapped
        }
    }
    
    // Called whenever the user taps on the map
    func onTapped(screenPoint: CGPoint) {
        
        var mapPoint = ScreenToMapSpace(screenPoint)

        print("Screen Point: \(screenPoint)")
        print("Map Point: \(mapPoint)")
        
        hitPoint = mapPoint
        
        for building in buildings {
            if building.hitRect.contains(mapPoint) {
                selectedBuilding = building
                building.roofNode.opacity = 0
                break;
            }
        }
        
        //if redRect.contains(mapPoint) {
        //    let node = svgView.getNode(byId: "Main_Roof")
        //    node?.opacity = 0
        //}
    }
    
    func computeTextOpacity() -> CGFloat {
        return 1.0
//        return transform.scale >= Self.textAppearScale ? 1.0 : 0.0
    }
    
    func drawText(_ context: inout GraphicsContext, _ string: String, _ point: CGPoint) {
        var textPos = CGPoint(x: point.x, y: point.y + 46)
        textPos.x -= viewSize.width * 0.5
        textPos.y -= viewSize.height * 0.5
        let transformedPos = transform.matrix.transformed2D(textPos.simd_float2)
        var textPoint = CGPoint(x: CGFloat(transformedPos.x), y: CGFloat(transformedPos.y))
        textPoint.y -= transform.translation.height
        textPoint.x -= transform.translation.width
        
        let font = Font.system(size: 20)
        
        let shadowText = Text(string)
            .font(font)
            .foregroundStyle(.black.opacity(computeTextOpacity()))
        let shadowTextPos = CGPoint(x: textPoint.x + 2, y: textPoint.y + 2)
        context.draw(context.resolve(shadowText), at: shadowTextPos, anchor: .center)
        
        let text = Text(string)
            .font(font)
            .foregroundStyle(.white.opacity(computeTextOpacity()))
        context.draw(context.resolve(text), at: textPoint, anchor: .center)
    }
    
    private func setupHitBox() {
        
        //let node = svgView.getNode(byId: "Main_HitBox")
        //if let hitBox = node as? SVGRect {
        //    redHitBox = hitBox
        //    redRect = CGRect(
        //        x: hitBox.x,
        //        y: hitBox.y,
        //        width: hitBox.width,
        //        height: hitBox.height)
        //} else {
        //    redRect = CGRect(x: 100, y: 100, width: 100, height: 100)
        //}
        
        //redRect = CGRect(x: 100, y: 100, width: 100, height: 100)
        //print("\(redRect)")
    }
    
    var body: some View {
        ZStack {
            Color("MapBackground", bundle: Bundle.main)
            
            svgView
                .transformEffect(transform)
                .background(GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            DispatchQueue.main.async {
                                viewSize = geometry.size
                                svgDisplayScale = viewSize.width / Self.svgSize.width
                                svgDisplaySize = CGSize(
                                    width: Self.svgSize.width * svgDisplayScale,
                                    height: Self.svgSize.height * svgDisplayScale)
                                setupHitBox()
                            }
                        }
                })

            Canvas { context, _ in
                // Draw hit detection point for debugging
                
                
                for building in buildings {
                    
                    let mapPoint = CGPoint(
                        x: building.hitRect.midX,
                        y: building.hitRect.midY)
                    
                    let screenPoint = MapToScreenSpace(mapPoint)
                    
                    context.fill(
                        Path(CGRect(
                            x: screenPoint.x,
                            y: screenPoint.y,
                            width: 50,
                            height: 50)),
                        with: .color(.blue))
                    

                    
                   
//                    
//                    drawText(&context, building.name, screenPoint)
                }
                
//                let point = MapToScreenSpace(hitPoint)

//                )
            }
        }
        .transformGesture(transform: transform, draggingDisabled: true, onTap: onTapped)
        //.ignoresSafeArea()
    }
}

#Preview {
    MapView()
}
