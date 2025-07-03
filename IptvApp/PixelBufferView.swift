import SwiftUI
import CoreImage
import CoreVideo

struct PixelBufferView: NSViewRepresentable {
    @Binding var pixelBuffer: CVPixelBuffer?

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        guard let pixelBuffer = pixelBuffer else {
            nsView.image = nil
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        nsView.image = nsImage
    }
}
