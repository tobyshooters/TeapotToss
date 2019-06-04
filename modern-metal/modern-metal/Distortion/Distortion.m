//
//  Distortion.m
//  modern-metal
//
//  Created by Cristobal Sciutto on 6/3/19.
//  Copyright © 2019 Metal By Example. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Distortion.h"

// The following reference implementation illustrates how to use the lensDistortionLookupTable,
// inverseLensDistortionLookupTable, and lensDistortionCenter properties to find points in the
// lens-distorted or undistorted (rectilinear, corrected) space. If you have a distorted image
// (such as a photo taken by a camera) and want to find a particular point in a corresponding
// undistorted image, you would call the sample method below using the inverseLensDistortionLookupTable.
// If you have an undistorted (aka distortion-corrected) image and want to find a point in the
// distorted image's space, you would call the sample method below using the lensDistortionLookupTable.

// To apply distortion correction to an image, you'd begin with an empty destination buffer and iterate through it
// row by row, calling the sample implementation below for each point in the output image, passing the
// lensDistortionLookupTable to find the corresponding value in the distorted image, and write it to your
// output buffer. Please note that the "point", "opticalCenter", and "imageSize" parameters below must be
// in the same coordinate system, i.e. both at full resolution, or both scaled to a different resolution but
// with the same aspect ratio.

// The reference function below returns floating-point x and y values. If you wish to match the results with
// actual pixels in a bitmap, you should either round to the nearest integer value or interpolate from surrounding
// integer positions (i.e. bilinear interpolation from the 4 surrounding pixels).

@implementation Distortion

- (CGPoint) lensDistortionPointForPoint: (CGPoint)  point
                            lookupTable: (NSData *) lookupTable
                distortionOpticalCenter: (CGPoint)  opticalCenter
                              imageSize: (CGSize)   imageSize
{
    // The lookup table holds the relative radial magnification for n linearly spaced radii.
    // The first position corresponds to radius = 0
    // The last position corresponds to the largest radius found in the image.
    
    // Determine the maximum radius.
    float delta_ocx_max = MAX( opticalCenter.x, imageSize.width  - opticalCenter.x );
    float delta_ocy_max = MAX( opticalCenter.y, imageSize.height - opticalCenter.y );
    float r_max = sqrtf( delta_ocx_max * delta_ocx_max + delta_ocy_max * delta_ocy_max );
    
    // Determine the vector from the optical center to the given point.
    float v_point_x = point.x - opticalCenter.x;
    float v_point_y = point.y - opticalCenter.y;
    
    // Determine the radius of the given point.
    float r_point = sqrtf( v_point_x * v_point_x + v_point_y * v_point_y );
    
    // Look up the relative radial magnification to apply in the provided lookup table
    float magnification;
    const float *lookupTableValues = lookupTable.bytes;
    NSUInteger lookupTableCount = lookupTable.length / sizeof(float);
    
    if ( r_point < r_max ) {
        // Linear interpolation
        float val   = r_point * ( lookupTableCount - 1 ) / r_max;
        int   idx   = (int)val;
        float frac  = val - idx;
        
        float mag_1 = lookupTableValues[idx];
        float mag_2 = lookupTableValues[idx + 1];
        
        magnification = ( 1.0f - frac ) * mag_1 + frac * mag_2;
    }
    else {
        magnification = lookupTableValues[lookupTableCount - 1];
    }
    
    // Apply radial magnification
    float new_v_point_x = v_point_x + magnification * v_point_x;
    float new_v_point_y = v_point_y + magnification * v_point_y;
    
    // Construct output
    return CGPointMake( opticalCenter.x + new_v_point_x, opticalCenter.y + new_v_point_y );
}

@end
