import CoreImage
import UIKit

struct RuinStyle: Identifiable {
    let id: String
    let name: String
    let nameEn: String
    let icon: String
    let apply: (CIImage) -> CIImage?
}

final class RuinFilterEngine {
    static let context = CIContext(options: [.workingColorSpace: NSNull()])

    static let styles: [RuinStyle] = [
        RuinStyle(id: "haunted", name: "幽霊屋敷", nameEn: "Haunted", icon: "moon.haze.fill") { img in
            applyHaunted(img)
        },
        RuinStyle(id: "nightmare", name: "悪夢", nameEn: "Nightmare", icon: "eye.trianglebadge.exclamationmark") { img in
            applyNightmare(img)
        },
        RuinStyle(id: "abandoned", name: "廃墟", nameEn: "Abandoned", icon: "building.2.fill") { img in
            applyAbandoned(img)
        },
        RuinStyle(id: "overgrown", name: "侵食", nameEn: "Overgrown", icon: "leaf.fill") { img in
            applyOvergrown(img)
        },
        RuinStyle(id: "postapoc", name: "終末", nameEn: "Aftermath", icon: "bolt.shield.fill") { img in
            applyPostApocalypse(img)
        },
        RuinStyle(id: "industrial", name: "錆工場", nameEn: "Industrial", icon: "gearshape.2.fill") { img in
            applyIndustrial(img)
        }
    ]

    static func render(_ ciImage: CIImage, orientation: UIImage.Orientation = .up) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: orientation)
    }

    static func applyAbandoned(_ input: CIImage) -> CIImage? {
        input
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.18,
                kCIInputContrastKey: 1.35,
                kCIInputBrightnessKey: -0.10
            ])
            .applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: 0.42])
            .applyingFilter("CIVignette", parameters: [kCIInputIntensityKey: 2.1, kCIInputRadiusKey: 1.45])
            .addingGrain(intensity: 0.12)
    }

    static func applyOvergrown(_ input: CIImage) -> CIImage? {
        input
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.55,
                kCIInputContrastKey: 1.22,
                kCIInputBrightnessKey: -0.08
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0.72, y: 0.00, z: 0.00, w: 0),
                "inputGVector": CIVector(x: 0.05, y: 1.10, z: 0.02, w: 0),
                "inputBVector": CIVector(x: 0.00, y: 0.00, z: 0.76, w: 0),
                "inputBiasVector": CIVector(x: -0.02, y: 0.05, z: -0.04, w: 0)
            ])
            .applyingFilter("CIVignette", parameters: [kCIInputIntensityKey: 1.8, kCIInputRadiusKey: 1.8])
            .addingGrain(intensity: 0.10)
    }

    static func applyPostApocalypse(_ input: CIImage) -> CIImage? {
        input
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.36,
                kCIInputContrastKey: 1.65,
                kCIInputBrightnessKey: -0.11
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.22, y: 0.00, z: 0.00, w: 0),
                "inputGVector": CIVector(x: 0.00, y: 0.84, z: 0.00, w: 0),
                "inputBVector": CIVector(x: 0.00, y: 0.00, z: 0.62, w: 0),
                "inputBiasVector": CIVector(x: 0.07, y: 0.00, z: -0.06, w: 0)
            ])
            .applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: 0.62])
            .applyingFilter("CIVignette", parameters: [kCIInputIntensityKey: 2.5, kCIInputRadiusKey: 1.25])
            .addingGrain(intensity: 0.16)
    }

    static func applyHaunted(_ input: CIImage) -> CIImage? {
        input
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.12,
                kCIInputContrastKey: 1.48,
                kCIInputBrightnessKey: -0.16
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 0.60, y: 0.00, z: 0.00, w: 0),
                "inputGVector": CIVector(x: 0.00, y: 0.72, z: 0.00, w: 0),
                "inputBVector": CIVector(x: 0.00, y: 0.04, z: 1.25, w: 0),
                "inputBiasVector": CIVector(x: -0.05, y: -0.02, z: 0.08, w: 0)
            ])
            .applyingFilter("CIBloom", parameters: [kCIInputIntensityKey: 0.14, kCIInputRadiusKey: 8.0])
            .applyingFilter("CIVignette", parameters: [kCIInputIntensityKey: 3.0, kCIInputRadiusKey: 1.1])
            .addingGrain(intensity: 0.13)
    }

    static func applyNightmare(_ input: CIImage) -> CIImage? {
        let base = input
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.06,
                kCIInputContrastKey: 1.85,
                kCIInputBrightnessKey: -0.20
            ])
            .applyingFilter("CIPhotoEffectNoir")

        let redShift = base.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.15, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0.42, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0.48, w: 0),
            "inputBiasVector": CIVector(x: 0.08, y: -0.04, z: -0.04, w: 0)
        ])

        return redShift
            .applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: 0.95])
            .applyingFilter("CIVignette", parameters: [kCIInputIntensityKey: 3.4, kCIInputRadiusKey: 0.9])
            .addingGrain(intensity: 0.20)
    }

    static func applyIndustrial(_ input: CIImage) -> CIImage? {
        input
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.28,
                kCIInputContrastKey: 1.55,
                kCIInputBrightnessKey: -0.12
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.08, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0.78, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.55, w: 0),
                "inputBiasVector": CIVector(x: 0.04, y: -0.02, z: -0.06, w: 0)
            ])
            .applyingFilter("CIVignette", parameters: [kCIInputIntensityKey: 2.4, kCIInputRadiusKey: 1.3])
            .addingGrain(intensity: 0.18)
    }

    static func makeSampleRuinImage() -> UIImage {
        let size = CGSize(width: 1290, height: 1640)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)

            let colors = [
                UIColor(red: 0.02, green: 0.025, blue: 0.03, alpha: 1).cgColor,
                UIColor(red: 0.08, green: 0.04, blue: 0.045, alpha: 1).cgColor,
                UIColor.black.cgColor
            ] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.52, 1])!
            cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])

            cg.setFillColor(UIColor(red: 0.11, green: 0.10, blue: 0.095, alpha: 1).cgColor)
            let building = CGRect(x: 145, y: 390, width: 1000, height: 820)
            cg.fill(building)

            cg.setFillColor(UIColor(red: 0.035, green: 0.035, blue: 0.038, alpha: 1).cgColor)
            for row in 0..<4 {
                for col in 0..<5 {
                    let x = 210 + col * 180
                    let y = 470 + row * 150
                    let window = CGRect(x: CGFloat(x), y: CGFloat(y), width: 92, height: 90)
                    cg.fill(window)
                    if (row + col).isMultiple(of: 3) {
                        cg.setFillColor(UIColor(red: 0.72, green: 0.04, blue: 0.04, alpha: 0.7).cgColor)
                        cg.fill(CGRect(x: window.midX - 10, y: window.midY - 10, width: 20, height: 20))
                        cg.setFillColor(UIColor(red: 0.035, green: 0.035, blue: 0.038, alpha: 1).cgColor)
                    }
                }
            }

            cg.setFillColor(UIColor(red: 0.035, green: 0.03, blue: 0.03, alpha: 1).cgColor)
            cg.fill(CGRect(x: 500, y: 920, width: 280, height: 290))

            cg.setStrokeColor(UIColor(red: 0.18, green: 0.18, blue: 0.17, alpha: 1).cgColor)
            cg.setLineWidth(14)
            for i in 0..<11 {
                let x = CGFloat(80 + i * 116)
                cg.move(to: CGPoint(x: x, y: 1150))
                cg.addLine(to: CGPoint(x: x - 130, y: 1360))
                cg.strokePath()
            }

            cg.setFillColor(UIColor.black.withAlphaComponent(0.35).cgColor)
            cg.fill(CGRect(x: 0, y: 1180, width: size.width, height: 460))

            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.14).cgColor)
            cg.setLineWidth(2)
            for i in 0..<34 {
                let x = CGFloat((i * 97) % 1290)
                let y = CGFloat(240 + (i * 71) % 1080)
                cg.move(to: CGPoint(x: x, y: y))
                cg.addLine(to: CGPoint(x: x + CGFloat((i % 5) - 2) * 34, y: y + 120))
                cg.strokePath()
            }

            cg.setFillColor(UIColor.white.withAlphaComponent(0.09).cgColor)
            for i in 0..<26 {
                let x = CGFloat((i * 153) % 1290)
                let y = CGFloat((i * 89) % 1500)
                cg.fillEllipse(in: CGRect(x: x, y: y, width: 130, height: 34))
            }
        }
    }
}

private extension CIImage {
    func addingGrain(intensity: CGFloat) -> CIImage {
        let noise = CIFilter(name: "CIRandomGenerator")!.outputImage!
            .cropped(to: extent)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 2.2,
                kCIInputBrightnessKey: -0.5
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: intensity)
            ])

        return noise.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: self
        ])
    }
}
