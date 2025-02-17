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

    private static let textAppearScale = 7.0
    @StateObject private var transform = TouchTransform(translation: CGSize(width: 100, height: 190), scale: 3, scaleRange: 3...30, rotationRange: 0...0)
    @State private var canvasSize: CGSize = CGSize()
    @State private var svgView: SVGView
    private var svgText: String
    private var redHitBox: SVGRect!
    
    init() {
        if let file = Bundle.main.url(forResource: "Tandem3", withExtension: "svg")
        {
            do {
                svgText = try String(contentsOf: file, encoding: .utf8)
            } catch {
                svgText = ""
                print("Failed to load SVG text from file")
            }
        }
        else
        {
            svgText = ""
        }
        
        self.svgView = SVGView(contentsOf: Bundle.main.url(forResource: "Tandem3", withExtension: "svg")!)
        
        let node = self.svgView.getNode(byId: "Main_HitBox")
        if let hitBox = node as? SVGRect {
            redHitBox = hitBox
        }
        //node?.opacity = 0
    }
    
    func applyTranslateTransform(to context: inout GraphicsContext) {
        context.translateBy(
            x: transform.translation.width,
            y: transform.translation.height)
    }
    
    // Applies the translation and scale transforms
    func applyScaleTransform(to context: inout GraphicsContext) {
        
        context.translateBy(
            x: canvasSize.width * 0.5,
            y: canvasSize.height * 0.5)
        
        let scale = CGFloat(transform.floatScale)
        context.scaleBy(x: scale, y: scale)
        
        context.translateBy(
            x: canvasSize.width * -0.5,
            y: canvasSize.height * -0.5)
    }
    
    func resetTransform(to context: inout GraphicsContext) {
        context.transform = CGAffineTransform.identity
    }
    
    func onTapped(location: CGPoint) {
        
        let simdTransformedLoc = transform
            .matrixInveresed
            .transformed2D(location.simd_float2)
        var point = CGPoint(x: CGFloat(simdTransformedLoc.x), y: CGFloat(simdTransformedLoc.y))
        point.x += canvasSize.width * 0.5
        point.y += canvasSize.height * 0.5
        
        if (point.x >= redHitBox.x && point.y >= redHitBox.y && point.x < redHitBox.x + redHitBox.width && point.y < redHitBox.y + redHitBox.height) {
            redHitBox.fill = SVGColor.init(r: 0, g: 255, b: 0)
        }
    }
    
    func computeTextOpacity() -> CGFloat {
        return transform.scale >= Self.textAppearScale ? 1.0 : 0.0
    }
    
    func drawText(_ context: inout GraphicsContext, _ string: String, _ point: CGPoint) {
        var textPos = CGPoint(x: point.x, y: point.y + 46)
        textPos.x -= canvasSize.width * 0.5
        textPos.y -= canvasSize.height * 0.5
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
    
    var body: some View {
        ZStack {
            Color("MapBackground", bundle: Bundle.main)
            

            
            GeometryReader { geometry in
                canvasSize = geometry.size
                
                svgView
                    .transformEffect(transform)
                
                Canvas { context, size in
                    
                    //applyTranslateTransform(to: &context)
                    
                    //drawText(&context, "Math/Science Building", CGPoint(x: 205, y: 285))
                    //drawText(&context, "Community Hall", CGPoint(x: 125, y: 310))
                    //drawText(&context, "Main Building", CGPoint(x: 170, y: 345))
                    //drawText(&context, "Arts Annex", CGPoint(x: 200, y: 315))
                    //drawText(&context, "Pavilion", CGPoint(x: 130, y: 285))
                }
            }
        }
        .transformGesture(transform: transform, draggingDisabled: true, onTap: onTapped)
        .ignoresSafeArea()
    }
}

#Preview {
    MapView()
}
