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

    @State private var circleColor: Color = .blue
    @StateObject var transform = TouchTransform(translation: CGSize(width: 100, height: 190), scale: 3, scaleRange: 3...30, rotationRange: 0...0)
    private var circlePath = Path(ellipseIn: CGRect(x: 0, y: 0, width: 100, height:100))
    @State private var canvasSize: CGSize = CGSize()
    @State private var svgView: SVGView
    
    init() {
        svgView = SVGView(contentsOf: Bundle.main.url(forResource: "Map", withExtension: "svg")!)
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
        
        if circlePath.contains(point) {
            if circleColor == .blue {
                circleColor = .red
            } else {
                circleColor = .blue
            }
        }
    }
    
    func computeTextOpacity() -> CGFloat {
        return (transform.scale - 2) * 3
    }
    
    func drawText(_ context: inout GraphicsContext, _ string: String, _ point: CGPoint) {
        var textPos = CGPoint(x: point.x, y: point.y)
        textPos.x -= canvasSize.width * 0.5
        textPos.y -= canvasSize.height * 0.5
        let transformedPos = transform.matrix.transformed2D(textPos.simd_float2)
        var textPoint = CGPoint(x: CGFloat(transformedPos.x), y: CGFloat(transformedPos.y))
        textPoint.y -= transform.translation.height
        textPoint.x -= transform.translation.width
        
        let text = Text(string)
            .font(.system(size:15))
            .foregroundStyle(.white.opacity(computeTextOpacity()))
        let resolvedText = context.resolve(text)
        context.draw(resolvedText, at: textPoint, anchor: .center)
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.4, green: 0.6, blue: 0.3)
            
            svgView
                .transformEffect(transform)
            
            GeometryReader { geometry in
                Canvas { context, size in
                    
                    applyTranslateTransform(to: &context)
                    
                    drawText(&context, "Math/Science Building", CGPoint(x: 205, y: 285))
                    drawText(&context, "Community Hall", CGPoint(x: 125, y: 310))
                    drawText(&context, "Main Building", CGPoint(x: 170, y: 345))
                    drawText(&context, "Arts Annex", CGPoint(x: 200, y: 315))
                    drawText(&context, "Pavilion", CGPoint(x: 130, y: 285))
                }
                .onAppear {
                    canvasSize = geometry.size
                }
            }
        }
        .transformGesture(transform: transform, draggingDisabled: true, onTap: onTapped)
        .clipped()
    }
}

#Preview {
    MapView()
}
