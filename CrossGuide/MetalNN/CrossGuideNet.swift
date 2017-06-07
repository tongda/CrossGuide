//
//  CrossGuideNet.swift
//  CrossGuide
//
//  Created by Ruoyu Fu on 7/6/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import Foundation
import MetalPerformanceShaders


func CrossGuideNet(device: MTLDevice) -> Layer {

    let relu = MPSCNNNeuronReLU(device: device, a: 0)
    let sigmoid = MPSCNNNeuronSigmoid(device: device)

    let input = Input(device: device)
    let poolMax = PoolingMax(device: device)

    let conv1_1 = Conv2d(kernelWidth:1, kernelHeight:1, inputFeatures: 3, outputFeatures: 16,  activation: relu, device: device, name: "vgg16_conv1_1")
    let conv1_2 = Conv2d(kernelWidth:5, kernelHeight:5, inputFeatures: 16, outputFeatures: 32,  activation: relu, device: device, name: "vgg16_conv1_1")
    let conv2 = Conv2d(kernelWidth:5, kernelHeight:5, inputFeatures: 32,   outputFeatures: 32,  activation: relu, device: device, name: "vgg16_conv1_1")
    let conv3 = Conv2d(kernelWidth:5, kernelHeight:5, inputFeatures: 32,   outputFeatures: 64,  activation: relu, device: device, name: "vgg16_conv1_1")
    let conv4 = Conv2d(kernelWidth:3, kernelHeight:3, inputFeatures: 64,   outputFeatures: 64,  activation: relu, device: device, name: "vgg16_conv1_1")
    let conv5 = Conv2d(kernelWidth:3, kernelHeight:3, inputFeatures: 64,   outputFeatures: 128,  activation: relu, device: device, name: "vgg16_conv1_1")


    return { raw in
        let input = raw

        
        return raw
    }
}
