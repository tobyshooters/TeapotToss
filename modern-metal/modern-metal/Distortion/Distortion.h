//
//  Distortion.h
//  modern-metal
//
//  Created by Cristobal Sciutto on 6/3/19.
//  Copyright © 2019 Metal By Example. All rights reserved.
//

#ifndef Distortion_h
#define Distortion_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Distortion : NSObject {}

- (CGPoint) lensDistortionPointForPoint: (CGPoint)  point
                            lookupTable: (NSData *) lookupTable
                distortionOpticalCenter: (CGPoint)  opticalCenter
                              imageSize: (CGSize)   imageSize;

@end

#endif /* Distortion_h */
