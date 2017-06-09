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
    func shouldTurn(commond: Command)
}

class AdjustService {
    weak var delegate: AdjustServiceDelegate?
    var array = FIFO()
    let threshold: CGFloat = 1
    
    func insertData(degree: CGFloat) {
        array.insertData(data: degree)
        guard let average = array.getAverageValue() else {
            return
        }
        
        if average > threshold {
            delegate?.shouldTurn(commond: Command.left(degree: 0))
        }
    }
    
    func reset() {
        array.emptyArray()
    }
}

struct FIFO {
    var array = [CGFloat](repeating: 0.0, count: 4)
    var currentIndex: Int = 0
    var nextIndex: Int = 0
    
    mutating func insertData(data: CGFloat) {
        array[nextIndex] = data
        currentIndex = nextIndex
        nextIndex = (nextIndex + 1) % array.count
    }
    
    func getCurrentData() -> CGFloat? {
        if currentIndex == nextIndex {
            return nil
        }
        
        return array[currentIndex]
    }
    
    func getAverageValue() -> CGFloat? {
        if currentIndex == nextIndex {
            return nil
        }
        
        return array.average
    }
    
    mutating func emptyArray() {
        array = [CGFloat](repeating: 0.0, count: 4)
    }
}

extension Array where Element == CGFloat {
    var total: Element {
        return reduce(0, +)
    }
    var average: CGFloat {
        return isEmpty ? 0 : reduce(0, +) / CGFloat(count)
    }
}
