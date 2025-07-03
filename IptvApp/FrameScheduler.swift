#if os(macOS)
import AppKit
#else
import UIKit
#endif

class FrameScheduler {
    var frameCallback: (() -> Void)?
    
    #if os(macOS)
    private var displayLink: CVDisplayLink?
    #else
    private var displayLink: CADisplayLink?
    #endif

    init() {
        #if os(macOS)
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, { (_, _, _, _, _, userInfo) -> CVReturn in
            let scheduler = Unmanaged<FrameScheduler>.fromOpaque(userInfo!).takeUnretainedValue()
            scheduler.tick()
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(displayLink!)
        #else
        displayLink = CADisplayLink(target: self, selector: #selector(tickWrapper))
        displayLink?.add(to: .main, forMode: .default)
        #endif
    }

    #if os(iOS) || os(tvOS)
    @objc private func tickWrapper() {
        tick()
    }
    #endif

    private func tick() {
        frameCallback?()
    }

    deinit {
        #if os(macOS)
        CVDisplayLinkStop(displayLink!)
        #else
        displayLink?.invalidate()
        #endif
    }
}
