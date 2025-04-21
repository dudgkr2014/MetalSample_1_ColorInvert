//
//  MetalVideoFilterView.swift
//  MetalSample_1_ColorInvert
//
//  Created by 우영학 on 4/20/25.
//

import AVFoundation
import MetalKit
import SwiftUI

struct MetalVideoFilterView: UIViewRepresentable {
  
  func makeUIView(context: Context) -> MTKView {
    let mtkView = MTKView()
    mtkView.preferredFramesPerSecond = 30
    mtkView.delegate = context.coordinator
    mtkView.device = MTLCreateSystemDefaultDevice()
    context.coordinator.setupMetal(view: mtkView)
    context.coordinator.setupCaptureSession(on: mtkView)
    return mtkView
  }
  
  func updateUIView(_ uiView: MTKView, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    return Coordinator()
  }
}
