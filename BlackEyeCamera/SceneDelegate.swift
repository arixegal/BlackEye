//
//  SceneDelegate.swift
//  BlackEyeCamera
//
//  Created by Arik Segal on 02/11/2022.
//

import UIKit
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func sceneDidBecomeActive(_ scene: UIScene) {
        DimUnDim.shared.dim()
    }
    func sceneWillResignActive(_ scene: UIScene) {
        DimUnDim.shared.unDim()
    }
}

