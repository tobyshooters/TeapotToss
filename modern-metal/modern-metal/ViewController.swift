
import UIKit
import MetalKit
import ModelIO
import AVFoundation

class ViewController: UIViewController, AVCaptureDataOutputSynchronizerDelegate {
    
    var mtkView: MTKView!
    var renderer: Renderer!

    @IBAction func rotationSwitch(_ sender: Any) {
    }
    
    private let deviceDiscovery = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInDualCamera,
                      .builtInTrueDepthCamera],
        mediaType: .video,
        position: .back
    )
    
    private let avSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [])
    private var videoDeviceInput: AVCaptureDeviceInput!
    
    private let dataOutputQueue = DispatchQueue(label: "video data queue", attributes: [])
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView = MTKView()
        mtkView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mtkView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[mtkView]|", options: [], metrics: nil, views: ["mtkView" : mtkView]))
        
        let device = MTLCreateSystemDefaultDevice()!
        mtkView.device = device
        
        mtkView.colorPixelFormat = .bgra8Unorm_srgb
        mtkView.depthStencilPixelFormat = .depth32Float
        
        renderer = Renderer(view: mtkView, device: device)
        mtkView.delegate = renderer

        sessionQueue.async {
            self.configureAvSession()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecognize:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc
    func handleTap(gestureRecognize: UITapGestureRecognizer) {
        print("TAP")
        renderer.toss()
    }

    override func viewWillAppear(_ animated: Bool) {
        sessionQueue.async {
            self.avSession.startRunning()
            print("Started AVCaptureSession")
        }
    }
    
    private func configureAvSession() {
        
        let defaultVideoDevice: AVCaptureDevice? = deviceDiscovery.devices.first
        
        guard let videoDevice = defaultVideoDevice else {
            print("Could not find any video device")
            return
        }
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        avSession.beginConfiguration()
        avSession.sessionPreset = AVCaptureSession.Preset.vga640x480
        
        // Add a video input
        guard avSession.canAddInput(videoDeviceInput) else {
            print("Could not add video device input to the session")
            avSession.commitConfiguration()
            return
        }
        avSession.addInput(videoDeviceInput)
        
        // Add a video data output
        if avSession.canAddOutput(videoDataOutput) {
            avSession.addOutput(videoDataOutput)
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        } else {
            print("Could not add video data output to the session")
            avSession.commitConfiguration()
            return
        }
        
        // Add a depth data output
        if avSession.canAddOutput(depthDataOutput) {
            // Map output to callback
            avSession.addOutput(depthDataOutput)
            depthDataOutput.isFilteringEnabled = true
            if let connection = depthDataOutput.connection(with: .depthData) {
                connection.isEnabled = true
            } else {
                print("No AVCaptureConnection")
            }
        } else {
            print("Could not add depth data output to the session")
            avSession.commitConfiguration()
            return
        }
        
        // Search for highest resolution with half-point depth values
        let depthFormats = videoDevice.activeFormat.supportedDepthDataFormats
        let filtered = depthFormats.filter({
            CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat16
        })
        let selectedFormat = filtered.max(by: {
            first, second in CMVideoFormatDescriptionGetDimensions(first.formatDescription).width < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
        })
        
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeDepthDataFormat = selectedFormat
            videoDevice.unlockForConfiguration()
        } catch {
            print("Could not lock device for configuration: \(error)")
            avSession.commitConfiguration()
            return
        }
        
        outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
        outputSynchronizer!.setDelegate(self, queue: dataOutputQueue)
        avSession.commitConfiguration()
    }
    
    func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer,
                                didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {
        
        // Read all outputs
        guard true,
            let synchedDepthData: AVCaptureSynchronizedDepthData =
            synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData,
            let synchedVideoData: AVCaptureSynchronizedSampleBufferData =
            synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData else { return }
        
        if synchedDepthData.depthDataWasDropped || synchedVideoData.sampleBufferWasDropped { return }

        // print(data.depthDataType) => kCVPixelFormatType_DepthFloat16
        let data: AVDepthData = synchedDepthData.depthData.convertToDepth()
        let depthImage = CIImage(cvPixelBuffer: data.depthDataMap, options: [:])
        depthImage.applyBlurAndGamma()

        renderer.depthPixelBuffer = depthImage.pixelBuffer
        renderer.videoPixelBuffer = CMSampleBufferGetImageBuffer(synchedVideoData.sampleBuffer)
    }
}

