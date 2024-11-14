import SwiftUI
import MetalKit

struct BubbleView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.delegate = context.coordinator
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.framebufferOnly = true
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        mtkView.drawableSize = mtkView.frame.size
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: BubbleView
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var bubbles: [Bubble] = []
        var bubbleBuffer: MTLBuffer!
        
        init(_ parent: BubbleView) {
            self.parent = parent
            super.init()
            
            guard let device = MTLCreateSystemDefaultDevice() else { return }
            self.device = device
            self.commandQueue = device.makeCommandQueue()
            
            setupPipeline()
            setupBubbles()
        }
        
        func setupPipeline() {
            let library = try! device.makeDefaultLibrary()
            let vertexFunction = library?.makeFunction(name: "bubbleVertex")
            let fragmentFunction = library?.makeFunction(name: "bubbleFragment")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            
            pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        
        func setupBubbles() {
            // 创建100个气泡
            for _ in 0..<100 {
                let bubble = Bubble(
                    position: SIMD2<Float>(Float.random(in: -1...1), Float.random(in: -1...1)),
                    size: Float.random(in: 10...30),
                    color: SIMD4<Float>(
                        Float.random(in: 0...1),
                        Float.random(in: 0...1),
                        Float.random(in: 0...1),
                        Float.random(in: 0.3...0.8)
                    ),
                    speed: Float.random(in: 0.2...1.0)
                )
                bubbles.append(bubble)
            }
            
            let bufferSize = MemoryLayout<Bubble>.stride * bubbles.count
            bubbleBuffer = device.makeBuffer(bytes: &bubbles, length: bufferSize, options: [])
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            
            updateBubbles()
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(bubbleBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: bubbles.count)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        func updateBubbles() {
            for i in 0..<bubbles.count {
                bubbles[i].position.y += bubbles[i].speed * 0.01
                
                if bubbles[i].position.y > 1.2 {
                    bubbles[i].position.y = -1.2
                    bubbles[i].position.x = Float.random(in: -1...1)
                }
            }
            
            let bufferSize = MemoryLayout<Bubble>.stride * bubbles.count
            bubbleBuffer.contents().copyMemory(from: &bubbles, byteCount: bufferSize)
        }
    }
}

struct Bubble {
    var position: SIMD2<Float>
    var size: Float
    var color: SIMD4<Float>
    var speed: Float
} 
