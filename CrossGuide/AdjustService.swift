//
//  AdjustService.swift
//  CrossGuide
//
//  Created by XueliangZhu on 09/06/2017.
//  Copyright © 2017 Ruoyu. All rights reserved.
//

import UIKit

enum Command {
    case left(degree: Int)
    case right(degree: Int)
}

protocol AdjustServiceDelegate: class {
    func shouldTurn(command: Command)
}

class AdjustService {
    weak var delegate: AdjustServiceDelegate?
    var array = FIFO()
    let threshold: Float = 1
    
    func insertData(degree: Float) {
        array.insertData(data: degree)
        guard let average = array.getAverageValue() else {
            return
        }
        guard let last = array.getCurrentData() else {
            return
        }
        
        let degree = abs(Int(last * 180 / 3.14))
        
        if average > threshold {
            delegate?.shouldTurn(command: Command.left(degree: Int(degree)))
        } else if average < -threshold {
            delegate?.shouldTurn(command: Command.right(degree: Int(degree)))
        }
    }
    
    func reset() {
        array.emptyArray()
    }
}

struct FIFO {
    var array = [Float](repeating: 0.0, count: 4)
    var currentIndex: Int = 0
    var nextIndex: Int = 0
    
    mutating func insertData(data: Float) {
        array[nextIndex] = data
        currentIndex = nextIndex
        nextIndex = (nextIndex + 1) % array.count
    }
    
    func getCurrentData() -> Float? {
        if currentIndex == nextIndex {
            return nil
        }
        
        return array[currentIndex]
    }
    
    func getAverageValue() -> Float? {
        if currentIndex == nextIndex {
            return nil
        }
        
        return array.average
    }
    
    mutating func emptyArray() {
        array = [Float](repeating: 0.0, count: 4)
    }
}

extension Array where Element == Float {
    var total: Element {
        return reduce(0, +)
    }
    var average: Float {
        return isEmpty ? 0 : reduce(0, +) / Float(count)
    }
}
