import SwiftUI
import IptvFFmpeg

struct ContentView: View {
    @State private var ffmpegVersion: String = "Loading..."

    var body: some View {
        VStack {
            Text("FFmpeg Version:")
                .font(.headline)
            Text(ffmpegVersion)
                .font(.subheadline)
                .padding()
        }
        .onAppear {
            ffmpegVersion = ffmpegVer()
        }
    }
}
