import SwiftUI
import IptvFFmpeg

struct ContentView: View {
    @StateObject private var player = IptvFFmpeg.IptvPlayer()

    var body: some View {
        MetalViewWrapper(player: player)
            .frame(maxWidth: CGFloat.infinity, maxHeight: CGFloat.infinity)
            .onAppear {
                player.play(url: URL(string: "https://bloomberg-bloombergtv-1-it.samsung.wurl.tv/manifest/playlist.m3u8")!)
            }
            .onDisappear {
                player.stop()
            }
    }
}
