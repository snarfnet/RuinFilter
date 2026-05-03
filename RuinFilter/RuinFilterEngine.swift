import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct RuinStyle: Identifiable {
    let id: String
    let name: String
    let nameEn: String
    let icon: String
    let apply: (CIImage) -> CIImage?
}

class RuinFilterEngine {
    static let context = CIContext()

    static let styles: [RuinStyle] = [
        RuinStyle(id: "abandoned", name: "廃墟", nameEn: "Abandoned", icon: "building.2") { img in
            applyAbandoned(img)
        },
        RuinStyle(id: "overgrown", name: "草むす", nameEn: "Overgrown", icon: "leaf") { img in
            applyOvergrown(img)
        },
        RuinStyle(id: "postapoc", name: "終末世界", nameEn: "Post-Apocalypse", icon: "bolt.shield") { img in
            applyPostApocalypse(img)
        },
        RuinStyle(id: "ancient", name: "古代遺跡", nameEn: "Ancient Ruin", icon: "building.columns") { img in
            applyAncient(img)
        },
        RuinStyle(id: "haunted", name: "心霊廃墟", nameEn: "Haunted", icon: "moon.stars") { img in
            applyHaunted(img)
        },
        RuinStyle(id: "industrial", name: "廃工場", nameEn: "Industrial", icon: "gearshape.2") { img in
            applyIndustrial(img)
        },
    ]

    static func render(_ ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Abandoned: desaturated, sepia, vignette, grain
    static func applyAbandoned(_ input: CIImage) -> CIImage? {
        var img = input

        // Desaturate
        img = img.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.3,
            kCIInputContrastKey: 1.2,
            kCIInputBrightnessKey: -0.05
        ])

        // Sepia overlay
        let sepia = img.applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: 0.4])
        img = sepia

        // Vignette
        img = img.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 1.5,
            kCIInputRadiusKey: 2.0
        ])

        // Noise
        img = addNoise(to: img, intensity: 0.06)

        return img
    }

    // MARK: - Overgrown: green tint, warm, slight blur edges
    static func applyOvergrown(_ input: CIImage) -> CIImage? {
        var img = input

        img = img.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.8,
            kCIInputContrastKey: 1.1,
            kCIInputBrightnessKey: -0.03
        ])

        // Green/warm tint
        img = img.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0.9, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1.1, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0.85, w: 0),
            "inputBiasVector": CIVector(x: 0.02, y: 0.04, z: 0, w: 0)
        ])

        img = img.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 1.0,
            kCIInputRadiusKey: 2.5
        ])

        img = addNoise(to: img, intensity: 0.04)

        return img
    }

    // MARK: - Post-Apocalypse: high contrast, orange/teal, dramatic
    static func applyPostApocalypse(_ input: CIImage) -> CIImage? {
        var img = input

        img = img.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.5,
            kCIInputContrastKey: 1.5,
            kCIInputBrightnessKey: -0.08
        ])

        // Orange/teal color grade
        img = img.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.15, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0.95, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0.85, w: 0),
            "inputBiasVector": CIVector(x: 0.05, y: 0.02, z: -0.02, w: 0)
        ])

        img = img.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 2.0,
            kCIInputRadiusKey: 1.5
        ])

        img = addNoise(to: img, intensity: 0.08)

        return img
    }

    // MARK: - Ancient Ruin: warm stone tones, weathered
    static func applyAncient(_ input: CIImage) -> CIImage? {
        var img = input

        img = img.applyingFilter("CISepiaTone", parameters: [kCIInputIntensityKey: 0.6])

        img = img.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.6,
            kCIInputContrastKey: 1.1,
            kCIInputBrightnessKey: 0.02
        ])

        img = img.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 1.2,
            kCIInputRadiusKey: 2.0
        ])

        img = addNoise(to: img, intensity: 0.07)

        return img
    }

    // MARK: - Haunted: cold blue, dark, eerie
    static func applyHaunted(_ input: CIImage) -> CIImage? {
        var img = input

        img = img.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.25,
            kCIInputContrastKey: 1.3,
            kCIInputBrightnessKey: -0.12
        ])

        // Cold blue tint
        img = img.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0.8, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0.85, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1.2, w: 0),
            "inputBiasVector": CIVector(x: -0.02, y: 0, z: 0.06, w: 0)
        ])

        img = img.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 2.5,
            kCIInputRadiusKey: 1.5
        ])

        img = addNoise(to: img, intensity: 0.05)

        return img
    }

    // MARK: - Industrial: rusty, high grain, desaturated warm
    static func applyIndustrial(_ input: CIImage) -> CIImage? {
        var img = input

        img = img.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.4,
            kCIInputContrastKey: 1.4,
            kCIInputBrightnessKey: -0.06
        ])

        // Rusty warm tint
        img = img.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 0.9, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 0.75, w: 0),
            "inputBiasVector": CIVector(x: 0.04, y: 0.02, z: -0.02, w: 0)
        ])

        img = img.applyingFilter("CIVignette", parameters: [
            kCIInputIntensityKey: 1.8,
            kCIInputRadiusKey: 1.8
        ])

        img = addNoise(to: img, intensity: 0.1)

        return img
    }

    // MARK: - Noise helper
    static func addNoise(to image: CIImage, intensity: Double) -> CIImage {
        let noise = CIFilter(name: "CIRandomGenerator")!.outputImage!
            .cropped(to: image.extent)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.0,
                kCIInputBrightnessKey: -0.5
            ])

        let blended = image.applyingFilter("CISourceOverCompositing", parameters: [
            kCIInputBackgroundImageKey: image
        ])

        return blended.applyingFilter("CIBlendWithAlphaMask", parameters: [
            kCIInputBackgroundImageKey: image.applyingFilter("CIAdditionCompositing", parameters: [
                kCIInputBackgroundImageKey: noise.applyingFilter("CIColorMatrix", parameters: [
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity))
                ])
            ]),
            kCIInputMaskImageKey: CIImage(color: .white).cropped(to: image.extent)
        ])
    }
}
