import SwiftUI
import MetalKit
import CoreVideo

// MARK: - SwiftUI MTKView Wrapper

struct MTKPixelBufferView: NSViewRepresentable {
    @Binding var pixelBuffer: CVPixelBuffer?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> MTKView {
        let device = MTLCreateSystemDefaultDevice()!
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.enableSetNeedsDisplay = true  // We control redraws
        mtkView.isPaused = true               // No continuous redraw
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false       // Required for texture reading
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.pixelBuffer = pixelBuffer
        nsView.setNeedsDisplay(nsView.bounds)
    }

    // MARK: - Coordinator as MTKViewDelegate

    class Coordinator: NSObject, MTKViewDelegate {
        var parent: MTKPixelBufferView
        var commandQueue: MTLCommandQueue
        var textureCache: CVMetalTextureCache?
        var texture: MTLTexture?

        var pixelBuffer: CVPixelBuffer?

        init(_ parent: MTKPixelBufferView) {
            self.parent = parent
            let device = MTLCreateSystemDefaultDevice()!
            self.commandQueue = device.makeCommandQueue()!
            super.init()
            CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        }

        func draw(in view: MTKView) {
            guard let pixelBuffer = pixelBuffer else {
                return
            }
            guard let textureCache = textureCache else { return }
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)

            var cvTextureOut: CVMetalTexture?

            // Create a Metal texture from CVPixelBuffer (BGRA format)
            let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                                   textureCache,
                                                                   pixelBuffer,
                                                                   nil,
                                                                   .bgra8Unorm,
                                                                   width,
                                                                   height,
                                                                   0,
                                                                   &cvTextureOut)
            guard result == kCVReturnSuccess, let cvTexture = cvTextureOut, let metalTexture = CVMetalTextureGetTexture(cvTexture) else {
                print("Failed to create Metal texture from CVPixelBuffer")
                return
            }
            self.texture = metalTexture

            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor else { return }

            let commandBuffer = commandQueue.makeCommandBuffer()!

            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!

            // Simple shader pipeline will be needed (we'll add below)
            encoder.setRenderPipelineState(parent.pipelineState(device: view.device!))

            // Pass texture to shader
            encoder.setFragmentTexture(metalTexture, index: 0)

            // Full-screen quad vertices, no vertex buffer for simplicity
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // No action needed here
        }
    }
}

// MARK: - Pipeline state and shaders (Metal Shading Language)

extension MTKPixelBufferView {
    func pipelineState(device: MTLDevice) -> MTLRenderPipelineState {
        // Lazy static cache so pipelineState is only created once per device
        struct Cache {
            static var pipelineState: MTLRenderPipelineState?
        }
        if let pipeline = Cache.pipelineState {
            return pipeline
        }

        // Create default library (include embedded Metal shaders below)
        let library = try! device.makeLibrary(source: metalShaderSource, options: nil)

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "samplingShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        Cache.pipelineState = pipelineState
        return pipelineState
    }
}

private let metalShaderSource = """
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
    const float4 positions[4] = {
        float4(-1.0, -1.0, 0, 1),
        float4( 1.0, -1.0, 0, 1),
        float4(-1.0,  1.0, 0, 1),
        float4( 1.0,  1.0, 0, 1)
    };
    const float2 texCoords[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
    };

    VertexOut out;
    out.position = positions[vertexID];
    out.textureCoordinate = texCoords[vertexID];
    return out;
}

fragment float4 samplingShader(VertexOut in [[stage_in]],
                             texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear);
    return texture.sample(textureSampler, in.textureCoordinate);
}
"""
