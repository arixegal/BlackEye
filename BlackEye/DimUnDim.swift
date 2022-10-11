//
//  DimUnDim.swift
//  BlackEye
//
//  Created by Arik Segal on 26/07/2022.
//

import UIKit

final class DimUnDim {
    static let shared = DimUnDim()
    private var originalBrightness = UIScreen.main.brightness
    
    func dim() {
        print("dim")
        UIScreen.main.wantsSoftwareDimming = true
        UIScreen.main.brightness = 0.0
    }
    
    func unDim() {
        print("unDim")
        UIScreen.main.brightness = originalBrightness
    }

}
