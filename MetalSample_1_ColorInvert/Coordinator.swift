//
//  Coordinator.swift
//  MetalSample_1_ColorInvert
//
//  Created by 우영학 on 4/20/25.
//

import AVFoundation
import MetalKit

final class Coordinator: NSObject {
  
  // MARK: - Properties
  
  private var device: MTLDevice!
  private var commandQueue: MTLCommandQueue!
  private var pipelineState: MTLRenderPipelineState!
  private var textureCache: CVMetalTextureCache!
  
  private var currentTexture: MTLTexture?
  private let captureSession = AVCaptureSession()
}

// MARK: - MTKViewDelegate

extension Coordinator: MTKViewDelegate {
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable,
          let texture = currentTexture,
          let desc = view.currentRenderPassDescriptor else { return }
    
    let commandBuffer = commandQueue.makeCommandBuffer()!
    let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: desc)!
    encoder.setRenderPipelineState(pipelineState)
    encoder.setFragmentTexture(texture, index: 0)
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    encoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension Coordinator: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    var cvTexture: CVMetalTexture?
    CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTexture)
    if let cvTex = cvTexture, let texture = CVMetalTextureGetTexture(cvTex) {
      currentTexture = texture
    }
  }
}

// MARK: - Setup

extension Coordinator {
  func setupMetal(view: MTKView) {
    device = view.device
    commandQueue = device.makeCommandQueue()
    
    let library = device.makeDefaultLibrary()!
    let vertexFunc = library.makeFunction(name: "vertexShader")
    let fragmentFunc = library.makeFunction(name: "filterFragment")
    let pipelineDesc = MTLRenderPipelineDescriptor()
    pipelineDesc.vertexFunction = vertexFunc
    pipelineDesc.fragmentFunction = fragmentFunc
    pipelineDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
    pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
    CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
  }
  
  func setupCaptureSession(on view: MTKView) {
    guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
          let input = try? AVCaptureDeviceInput(device: camera) else { return }
    captureSession.sessionPreset = .hd1280x720
    captureSession.addInput(input)
    
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
    captureSession.addOutput(videoOutput)
    
    // 카메라 방향 보정
    if let connection = videoOutput.connection(with: .video) {
      connection.videoOrientation = .portrait
      connection.isVideoMirrored = false
    }
    
    DispatchQueue.main.async { [weak self] in
      self?.captureSession.startRunning()
    }
  }
}

