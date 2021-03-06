//
//  CrossGuideNet.swift
//  CrossGuide
//
//  Created by Ruoyu Fu on 7/6/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import Foundation
import MetalPerformanceShaders


func CrossGuideNet(device: MTLDevice, group: String, inputSize: [Int]) -> Layer {
    let tanh = MPSCNNNeuronTanH(device: device, a:1, b:1)

    let image = Input(device: device, size: inputSize)
    let poolMax = PoolingMax(device: device)

    let conv1 = Conv2d(kernelWidth:1, kernelHeight:1, inputFeatures: 3, outputFeatures: 16,  activation: tanh, device: device, name: "conv2d_1", group: group)
    let conv2 = Conv2d(kernelWidth:5, kernelHeight:5, inputFeatures: 16, outputFeatures: 32,  activation: tanh, device: device, name: "conv2d_2", group: group)
    let conv3 = Conv2d(kernelWidth:5, kernelHeight:5, inputFeatures: 32,   outputFeatures: 32,  activation: tanh, device: device, name: "conv2d_3", group: group)
    let conv4 = Conv2d(kernelWidth:5, kernelHeight:5, inputFeatures: 32,   outputFeatures: 64,  activation: tanh, device: device, name: "conv2d_4", group: group)
    let conv5 = Conv2d(kernelWidth:3, kernelHeight:3, inputFeatures: 64,   outputFeatures: 64,  activation: tanh, device: device, name: "conv2d_5", group: group)
    let conv6 = Conv2d(kernelWidth:3, kernelHeight:3, inputFeatures: 64,   outputFeatures: 128,  activation: tanh, device: device, name: "conv2d_6", group: group)
    let dense1 = Dense(kernelWidth: inputSize[1] / 32, kernelHeight: inputSize[0] / 32, inputFeatures: 128, outputFeatures: 128, activation: tanh, device: device, name: "conv2d_7", group: group)
    let dense2 = Dense(kernelWidth: 1, kernelHeight: 1, inputFeatures: 128, outputFeatures: 64, activation: tanh, device: device, name: "conv2d_8", group: group)
    let dense3 = Dense(kernelWidth: 1, kernelHeight: 1, inputFeatures: 64, outputFeatures: 16, activation: tanh, device: device, name: "conv2d_9", group: group)
    let dense4 = Dense(kernelWidth: 1, kernelHeight: 1, inputFeatures: 16, outputFeatures: 2, activation: nil, device: device, name: "conv2d_10", group: group)

    return { raw in
        let input = raw
            |> image
        let pool1 = input
            |> conv1
            |> conv2
        let pool2 = pool1
            |> poolMax
            |> conv3
        let pool3 = pool2
            |> poolMax
            |> conv4
        let pool4 = pool3
            |> poolMax
            |> conv5
        let pool5 = pool4
            |> poolMax
            |> conv6
            |> poolMax
        let fc0 = pool5
            |> dense1
        let fc1 = fc0
            |> dense2
        let fc2 = fc1
            |> dense3
        let fc3 = fc2
            |> dense4
        return fc3
    }
}
