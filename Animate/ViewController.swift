//
//  ViewController.swift
//  Animate
//
//  Created by Mike on 7/21/16.
//  Copyright © 2016 Orologics. All rights reserved.
//

import UIKit
import GPUImage
import AVFoundation

class ViewController: UIViewController {

    private var movieMaker: MovieFaker?
    private var picture:PictureInput!
    let unsharpMask = UnsharpMask()
    let contrastFilter = ContrastAdjustment()
    let brightnessFilter = BrightnessAdjustment()
    private let rawDataOutput = RawDataOutput()
    private let rawDataInput = RawDataInput()
    var rawDataFrame = 0
    let viaRawDataOutput = true
    let excludeUnsharp = false  // works correctly if I change this to true

    @IBOutlet weak var renderView: RenderView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rawDataOutput.downloadBytes = { pixels, size, pixelFormat, imageOrientation in
            self.processWhenReady(pixels, size: size, pixelFormat: pixelFormat, orientation: imageOrientation)
        }
        brightnessFilter.brightness = 0.0
        if viaRawDataOutput {
            if excludeUnsharp {
                brightnessFilter --> contrastFilter --> rawDataOutput
            } else {
                unsharpMask --> brightnessFilter --> contrastFilter --> rawDataOutput
            }
            rawDataInput --> renderView
        } else {
            unsharpMask --> brightnessFilter --> contrastFilter --> renderView
        }
        DispatchQueue.main.async {
            self.initMovie()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initMovie() {
        movieMaker = MovieFaker(frames:36)
        movieMaker?.startReading()
        _ = processOneFrame()
        var fr = 1
        while !viaRawDataOutput && processOneFrame() {
            fr += 1
            print ("finished frame \(fr)")
        }
    }
    
    func processOneFrame()  -> Bool {
        if movieMaker!.status == .reading {
            let uiImage = movieMaker!.getNextMovieFrame()
            picture?.removeAllTargets()
            picture = PictureInput(image: uiImage)
            if excludeUnsharp {
                picture --> brightnessFilter
            } else {
                picture --> unsharpMask
            }
            picture.processImage()
            print("frame \(movieMaker!.at)")
            return true
        }
        return false
    }
    
    func processWhenReady(_ pixels:[UInt8], size: Size, pixelFormat: PixelFormat, orientation: ImageOrientation) {
        // Insert My Algorithm here
        rawDataInput.uploadBytes(pixels, size: size, pixelFormat: pixelFormat, orientation: orientation)
        rawDataFrame += 1
        print("finished frame \(self.rawDataFrame)")
        DispatchQueue.main.async {
            _ = self.processOneFrame()
        }
    }

}

class MovieFaker {
    var count = 0
    var at = 0
    var status = AVAssetReaderStatus.unknown
    
    init(frames: Int) {
        count = frames
    }
    
    func startReading() {
        at = 0
        status = AVAssetReaderStatus.reading
    }
    
    func getNextMovieFrame() -> UIImage {
        if at >= count {
            status = AVAssetReaderStatus.completed
        }
        let imageFromPath = UIImage(named: "TestPattern\(at % 2).jpg")
        at += 1
        
        return imageFromPath!
    }
    
}

