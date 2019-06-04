# iOS AR Occlusion in Metal
Extract image and depth buffer from `AVCaptureSession` and pass into Metal shader as texture.

![](https://media.giphy.com/media/LVsF3VQGjSWV52IKgn/giphy.gif)

### What we wanted to do

AR occlusion using the iPhone depth sensing

### What we tried

- Started an ARKit app, implemented occusion
    - Implemented occlusion by passing camera as texture to fragment shader and writing as object color
        - Visually looked great, needed depth data, which we could not get because ARKit has an AVCameraSession and you can't have more than one open, and they won't let you access the depth data from its AVCameraSession
- Well fuck you too ARKit, I don't need your attitude
- Created a new 3D game, that way we can have 3D objects and doesn't have an AVCameraSession so we can have our own.
    - Well, it doesn't have a camera, so we don't have the reality part of AR.
        - We fixed this by adding a 3D plane way in the back of the scene and just using camera data as a texture
        - How the hell are we going to align this to the screen? Create an object in the shader instead


