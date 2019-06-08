# iOS AR Occlusion in Metal
Extract image and depth buffer from `AVCaptureSession` and pass into Metal shader as texture.

Project Report available at `/docs/report.pdf`

### Basic Occlusion
![](https://media.giphy.com/media/LVsF3VQGjSWV52IKgn/giphy.gif)

### Teapot Toss

![](https://media.giphy.com/media/THYR7VpPYpCrw6XyYB/giphy.gif)

Reference template: <https://github.com/metal-by-example/modern-metal>

Important files:
- **ViewController.swift**: in this file contains all logic for initializing a session with the camera and extracting video and depth information. The depth information is processed in this file. It is also where the Renderer instance is initialized and the class which orchestrates the rendering process.
- **Renderer.swift**: the Renderer class is responsible for all the logic for teapot rendering and animation. It receives camera information as a parameter. This is where the rendering pipeline is determined, scene objects are described, and camera information is transformed from a pixel buffer into a texture.
- **Shaders.metal**: contains the shaders for both pasting the camera image onto the 3D plane, as well as lighting for the virtual depth map. The shader scales the depth map data to range of data and discretizes it. It then assigns the fragment color to either it’s described material or the video information.

Requirements:
- Mac OSx computer with XCode installed
- iPhone with dual camera (7 or more recent)

To run:
1. Install XCode on Mac OSx
2. `git clone https://github.com/tobyshooters/TeapotToss.git` in the desired directory
2. Connect phone to computer
3. Open `modern-metal.xcodeproj` file in XCode
4. Target connected iPhone
5. Click on build and run button
