import SwiftUI
import CoreVideo
import IptvFFmpeg

struct ContentView: View {
    @State private var currentFrame: CVPixelBuffer?
    @State private var scheduler: FrameScheduler? = nil

    private let player = IptvPlayer(url: "https://bloomberg-bloombergtv-1-it.samsung.wurl.tv/manifest/playlist.m3u8")

    var body: some View {
        MTKPixelBufferView(pixelBuffer: $currentFrame)
            .frame(width: 1280, height: 720)
            .onAppear {
                if scheduler == nil {
                    let s = FrameScheduler()
                    s.frameCallback = {
                        let frame = player.getNextFrame()
                        DispatchQueue.main.async {
                            self.currentFrame = frame
                        }
                    }
                    scheduler = s
                }
            }
    }
}
