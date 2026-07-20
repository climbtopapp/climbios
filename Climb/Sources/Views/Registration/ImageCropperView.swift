import SwiftUI

/// Image cropper view with pan and zoom, outputting a 500x500 square crop
/// Matches the web app's crop modal
struct ImageCropperView: View {
    let image: UIImage
    let onCropped: (UIImage) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0

    private let viewportSize: CGFloat = 250
    private let outputSize: CGFloat = 300

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                Text("Crop Photo")
                    .font(ClimbTheme.displayFont(size: 28))
                    .fontWeight(.bold)

                Text("Drag and zoom to focus on your face.")
                    .font(ClimbTheme.bodyFont(size: 13))
                    .foregroundColor(ClimbTheme.textMuted)

                // Crop viewport
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(scale)
                        .offset(offset)
                        .frame(width: viewportSize, height: viewportSize)
                        .clipped()
                }
                .frame(width: viewportSize, height: viewportSize)
                .background(ClimbTheme.bgSecondary)
                .overlay(
                    Rectangle()
                        .stroke(ClimbTheme.borderColor, lineWidth: 2)
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = lastScale * value
                            scale = min(max(newScale, 1.0), 3.0)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )

                // Zoom slider
                HStack(spacing: 10) {
                    Text("➖")
                        .font(.system(size: 14))

                    Slider(value: $scale, in: 1...3, step: 0.01)
                        .tint(ClimbTheme.primaryColor)
                        .onChange(of: scale) { _, newVal in
                            lastScale = newVal
                        }

                    Text("➕")
                        .font(.system(size: 14))
                }
                .padding(.horizontal)

                // Buttons
                HStack(spacing: 10) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(BrutalistSecondaryButtonStyle())
                    .frame(maxWidth: .infinity)

                    Button("Apply") {
                        let cropped = cropImage()
                        onCropped(cropped)
                    }
                    .buttonStyle(BrutalistPrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding(20)
            .background(ClimbTheme.bgSecondary)
            .navigationBarHidden(true)
        }
    }

    private func cropImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputSize, height: outputSize))

        return renderer.image { context in
            let ctx = context.cgContext

            // Calculate the image dimensions as displayed
            let imageAspect = image.size.width / image.size.height
            var displayWidth: CGFloat
            var displayHeight: CGFloat

            if imageAspect > 1 {
                displayHeight = viewportSize
                displayWidth = viewportSize * imageAspect
            } else {
                displayWidth = viewportSize
                displayHeight = viewportSize / imageAspect
            }

            displayWidth *= scale
            displayHeight *= scale

            // Center + offset
            let imgX = (viewportSize - displayWidth) / 2 + offset.width
            let imgY = (viewportSize - displayHeight) / 2 + offset.height

            // Map to output coordinates
            let scaleRatio = outputSize / viewportSize
            let drawRect = CGRect(
                x: imgX * scaleRatio,
                y: imgY * scaleRatio,
                width: displayWidth * scaleRatio,
                height: displayHeight * scaleRatio
            )

            ctx.clip(to: CGRect(x: 0, y: 0, width: outputSize, height: outputSize))

            if let cgImage = image.cgImage {
                // UIKit drawing with flipped coordinates
                ctx.translateBy(x: 0, y: outputSize)
                ctx.scaleBy(x: 1, y: -1)
                ctx.draw(cgImage, in: CGRect(
                    x: drawRect.origin.x,
                    y: outputSize - drawRect.origin.y - drawRect.height,
                    width: drawRect.width,
                    height: drawRect.height
                ))
            }
        }
    }
}
