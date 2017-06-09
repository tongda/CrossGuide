//
//  SpeechService.swift
//  CrossGuide
//
//  Created by XueliangZhu on 09/06/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import UIKit
import AVFoundation

class SpeechService: NSObject {
    
    fileprivate let synthesizer = AVSpeechSynthesizer()
    fileprivate var words: String?
    
    fileprivate var leftChannel: AVAudioSessionChannelDescription?
    fileprivate var rightChannel: AVAudioSessionChannelDescription?
    
    override init() {
        super.init()
        let avSession = AVAudioSession.sharedInstance()
        let route = avSession.currentRoute
        let outputPorts = route.outputs
        for outputPort in outputPorts {
            for channel in outputPort.channels! {
                if channel.channelName == "BLUEZ 2S by AfterShokz 左" {
                    leftChannel = channel
                } else if channel.channelName == "BLUEZ 2S by AfterShokz 右" {
                    rightChannel = channel
                }
            }
        }
    }
    
    func say(words: String, isLeft: Bool? = nil) {
        if synthesizer.isSpeaking {
            return
        }
        
        let utterance = AVSpeechUtterance(string: words)
        
        if let isLeft = isLeft {
            if isLeft {
                setLeftChannel()
            } else {
                setRightChannel()
            }
        } else {
            if #available(iOS 10.0, *) {
                synthesizer.outputChannels = []
            }
        }
        
        synthesizer.speak(utterance)
    }
    
    private func setLeftChannel() {
        if #available(iOS 10.0, *) {
            if let leftChannel = leftChannel {
                synthesizer.outputChannels = [leftChannel]
            }
        }
    }
    
    private func setRightChannel() {
        if #available(iOS 10.0, *) {
            if let rightChannel = rightChannel {
                synthesizer.outputChannels = [rightChannel]
            }
        }
    }
    
    func initChannel() {
        if #available(iOS 10.0, *) {
            synthesizer.outputChannels = []
        }
    }
}
