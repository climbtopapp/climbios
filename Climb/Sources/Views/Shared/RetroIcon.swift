import SwiftUI

/// Retro pixel-art icons matching the web app's SVG icons
struct RetroIcon {

    /// Mountain / Climb icon (pyramid steps)
    struct MountainIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Trophy / Summit icon
    struct TrophyIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "trophy.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Person icon
    struct PersonIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Star icon
    struct StarIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Group / Club icon
    struct GroupIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "person.3.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Camera icon
    struct CameraIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "camera.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Mail icon
    struct MailIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "envelope.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Settings gear icon
    struct GearIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "gearshape.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Share icon
    struct ShareIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "square.and.arrow.up")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Block/Ban icon
    struct BlockIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "nosign")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Shield icon
    struct ShieldIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Calendar icon (challenges)
    struct CalendarIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "calendar")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Globe icon
    struct GlobeIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "globe")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Map pin icon
    struct MapPinIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Video camera icon
    struct VideoCameraIcon: View {
        var size: CGFloat = 20
        var body: some View {
            Image(systemName: "video.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// The main Climb logo as a pixel mountain shape
    struct ClimbLogo: View {
        var size: CGFloat = 160

        var body: some View {
            Canvas { context, canvasSize in
                let unit = canvasSize.width / 16

                let rects: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat)] = [
                    (7, 4, 2, 2),
                    (6, 6, 4, 2),
                    (5, 8, 6, 2),
                    (4, 10, 8, 2),
                    (3, 12, 10, 2)
                ]

                // Background
                context.fill(
                    Path(CGRect(x: 0, y: 0, width: canvasSize.width, height: canvasSize.height)),
                    with: .color(ClimbTheme.primaryColor)
                )

                // Mountain steps
                for r in rects {
                    let rect = CGRect(x: r.x * unit, y: r.y * unit, width: r.w * unit, height: r.h * unit)
                    context.fill(Path(rect), with: .color(.white))
                }
            }
            .frame(width: size, height: size)
            .overlay(
                Rectangle()
                    .stroke(ClimbTheme.borderColor, lineWidth: 4)
            )
        }
    }

    /// Male symbol icon
    struct MaleIcon: View {
        var size: CGFloat = 48
        var body: some View {
            Image(systemName: "arrow.up.right.circle")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }

    /// Female symbol icon
    struct FemaleIcon: View {
        var size: CGFloat = 48
        var body: some View {
            Image(systemName: "plus.circle")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
    }
}
