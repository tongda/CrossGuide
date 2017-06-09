//
//  ViewController.swift
//  CrossGuide
//
//  Created by Ruoyu Fu on 7/6/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import UIKit
import CoreVideo
import MetalKit
import AVFoundation
import MetalPerformanceShaders
import Accelerate

protocol SettingDelegate: class {
    func didChangedSettings(threshold: Float, arrayCount: Int, timeInterval: Double)
}

class ViewController: UIViewController {

    @IBOutlet weak var mtkView: MTKView!
    @IBOutlet weak var previewLayer: UIView!
    @IBOutlet weak var arrow: UIImageView!
    
    var timer: Timer!
    var videoDevice: AVCaptureDevice!
    var captureDeviceInput: AVCaptureDeviceInput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    let session = AVCaptureSession()
    let output = AVCaptureVideoDataOutput()
    var crossGuide: Layer?
    var videoTextureCache : CVMetalTextureCache?
    var commandQueue: MTLCommandQueue!
    var displayPipeline: MTLComputePipelineState!

    let semaphoreDraw = DispatchSemaphore(value: 0)
    let semaphoreCapture = DispatchSemaphore(value: 1)

    var inputTexture:MTLTexture? = nil
    
    var adjustService: AdjustService!
    var speechService: SpeechService!
    var timeInterval = 0.2

    @IBOutlet weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        commandQueue = device.makeCommandQueue()
        guard let function = device.newDefaultLibrary()?.makeFunction(name: "display") else{
            return
        }


        displayPipeline = try! device.makeComputePipelineState(function: function)
        mtkView.device = device
        mtkView.delegate = self
        crossGuide = CrossGuideNet(device: device)
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &videoTextureCache)
        
        initService()
        videoInit()
    }
    
    @IBAction func editTapped(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingViewController") as! SettingViewController
        vc.delegate = self
        vc.timeInterval = timeInterval
        vc.arrayCount = adjustService.array.getCount()
        vc.threshold = adjustService.threshold
        show(vc, sender: nil)
    }

    func videoInit() {
        let queue = DispatchQueue(label: "com.color.back")
        output.setSampleBufferDelegate(self, queue: queue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        captureDeviceInput = try! AVCaptureDeviceInput(device: videoDevice)
        if session.canAddInput(captureDeviceInput) {
            session.addInput(captureDeviceInput)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        output.connection(withMediaType: AVMediaTypeVideo).videoOrientation = .portrait
        
        session.sessionPreset = AVCaptureSessionPreset352x288
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.frame = view.bounds
        previewLayer.layer.addSublayer(videoPreviewLayer)
        session.startRunning()
    }
    
    private func initService() {
        adjustService = AdjustService()
        adjustService.delegate = self
        speechService = SpeechService()
        speechService.initChannel()
    }
}

extension ViewController: SettingDelegate {
    func didChangedSettings(threshold: Float, arrayCount: Int, timeInterval: Double) {
        self.timeInterval = timeInterval
        self.adjustService = AdjustService(threshold: threshold, arrayCount: arrayCount)
        adjustService.delegate = self
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        semaphoreCapture.wait()
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        var yTextureRef : CVMetalTexture?
        let yWidth = CVPixelBufferGetWidth(pixelBuffer);
        let yHeight = CVPixelBufferGetHeight(pixelBuffer);

        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  videoTextureCache!,
                                                  pixelBuffer,
                                                  nil,
                                                  .rgba8Unorm,
                                                  yWidth, yHeight, 0,
                                                  &yTextureRef)
        inputTexture = CVMetalTextureGetTexture(yTextureRef!)
        semaphoreDraw.signal()
    }
}

extension ViewController: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize){

    }
    func draw(in view: MTKView) {
        semaphoreDraw.wait()
        guard let inputTexture = self.inputTexture else {
                return
        }
        let commandBuffer = commandQueue.makeCommandBuffer()
        let src = MPSImage(texture: inputTexture, featureChannels: 3)
        let (_, prediction) = crossGuide!(commandbuffer: commandBuffer, image: src)
        let scale = MPSCNNNeuronLinear(device: commandBuffer.device, a: 1, b: 0)
        let outID = MPSImageDescriptor(channelFormat: .float16, width: 1, height: 1, featureChannels: 3)
        let output = MPSImage(device: commandBuffer.device, imageDescriptor: outID)
        scale.encode(commandBuffer: commandBuffer, sourceImage: prediction, destinationImage: output)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        var outputArray = [UInt16](repeating: 3 , count: 3)
        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: 1, height: 1, depth: 1))
        output.texture.getBytes(&(outputArray[0]), bytesPerRow: 8, from: region, mipmapLevel: 0)
        let rotateRate = converFromUInt16ToFloat(input: &outputArray)
        UIView.animate(withDuration: 0.5) { [weak self] _ in
            self?.arrow.transform = CGAffineTransform(rotationAngle: -CGFloat(rotateRate[1]))
        }
        
        print(rotateRate)
        adjustService.insertData(degree: rotateRate[1])
        DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval) {
            self.semaphoreCapture.signal()
        }
    }
    
    private func converFromUInt16ToFloat(input: inout [UInt16]) -> [Float] {
        let n = 3
        var output = [Float](repeating: 0, count: n)
        var src = vImage_Buffer(data:&input, height:1, width:UInt(n), rowBytes:2*n)
        var dst = vImage_Buffer(data:&output, height:1, width:UInt(n), rowBytes:4*n)
        vImageConvert_Planar16FtoPlanarF(&src, &dst, 0)
        return output
    }
}

extension ViewController: AdjustServiceDelegate {
    func shouldTurn(command: Command) {
        speechService.say(command: command)
    }
}
