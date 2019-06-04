//
//  Extensions.swift
//  modern-metal
//
//  Created by Cristobal Sciutto on 6/3/19.
//  Copyright © 2019 Metal By Example. All rights reserved.
//

import AVFoundation
import MetalKit

extension AVDepthData {
    
    func convertToDepth() -> AVDepthData {
        let targetType: OSType
        switch depthDataType {
        case kCVPixelFormatType_DisparityFloat16:
            targetType = kCVPixelFormatType_DepthFloat16
        case kCVPixelFormatType_DisparityFloat32:
            targetType = kCVPixelFormatType_DepthFloat32
        default:
            return self
        }
        return converting(toDepthDataType: targetType)
    }
}

extension CIImage {
    func applyBlurAndGamma() -> CIImage {
        return clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": 3.0])
            .applyingFilter("CIGammaAdjust", parameters: ["inputPower": 0.5])
            .cropped(to: extent)
    }
}
