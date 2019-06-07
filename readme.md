# iOS AR Occlusion in Metal
Extract image and depth buffer from `AVCaptureSession` and pass into Metal shader as texture.

### Basic Occlusion
![](https://media.giphy.com/media/LVsF3VQGjSWV52IKgn/giphy.gif)

### Teapot Toss

![](https://media.giphy.com/media/THYR7VpPYpCrw6XyYB/giphy.gif)

Metal template: <https://github.com/metal-by-example/modern-metal>

Important files:
- **Renderer.swift**: contains all logic for teapot rendering and motion, as well as passing of video/depth textures to shader.
- **ViewController.swift**: captures video/depth from camera and applies gaussian blur to depth map.
- **Shaders.metal**: contains all the shaders, both for the video image on the background as well as the virtual teapot. Scales depth map data to range of interest and discretizes it, then conditionally assigns teapot color or video to fragment. 
