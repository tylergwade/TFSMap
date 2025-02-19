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
    @State private var redHitBox: SVGRect? // Make it optional for safety
    @State private var redRect: CGRect = .zero
    @State private var hitPoint: CGPoint = .zero
    @State private var isHitBoxTapped: Bool = false // Track tap state
    
    @State private var svgDisplayScale: CGFloat = 0
    @State private var svgDisplaySize: CGSize = .zero
    
    init() {
        
        // Load the SVG view
        let svgURL = Bundle.main.url(forResource: "Tandem5", withExtension: "svg")!
        self.svgView = SVGView(contentsOf: svgURL)
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
        
        //cLocation.x += canvasSize.width / 2
        //cLocation.y += canvasSize.height / 2
        
        //localHitPoint.x *= 2
        //localHitPoint.y *= 2
        
        //hitPoint = localHitPoint
        

        //print("Point: \(hitPoint)")
        
        if redRect.contains(mapPoint) {
        
            isHitBoxTapped.toggle() // Toggle hit detection state
            updateHitBoxColor()
        }
        
        //point.x += canvasSize.width * 0.5
        //point.y += canvasSize.height * 0.5
        
        //if (point.x >= redHitBox.x && point.y >= redHitBox.y && point.x < redHitBox.x + redHitBox.width && point.y < redHitBox.y + redHitBox.height) {
        //    redHitBox.fill = SVGColor.init(r: 0, g: 255, b: 0)
        //}
    }
    
    func computeTextOpacity() -> CGFloat {
        return transform.scale >= Self.textAppearScale ? 1.0 : 0.0
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
        let node = svgView.getNode(byId: "Main_HitBox")
        if let hitBox = node as? SVGRect {
            redHitBox = hitBox
            redRect = CGRect(
                x: hitBox.x,
                y: hitBox.y,
                width: hitBox.width,
                height: hitBox.height)
        } else {
            redRect = CGRect(x: 100, y: 100, width: 100, height: 100)
        }
        
        //redRect = CGRect(x: 100, y: 100, width: 100, height: 100)
        print("\(redRect)")
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
                
                let point = MapToScreenSpace(hitPoint)
                context.fill(
                    Path(CGRect(
                        x: point.x,
                        y: point.y,
                        width: 50,
                        height: 50)),
                    with: .color(.blue)
                )
            }
        }
        .transformGesture(transform: transform, draggingDisabled: true, onTap: onTapped)
        //.ignoresSafeArea()
    }
}

#Preview {
    MapView()
}
