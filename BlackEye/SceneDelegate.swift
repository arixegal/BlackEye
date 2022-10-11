//
//  SceneDelegate.swift
//  BlackEye
//
//  Created by Arik Segal on 26/07/2022.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func sceneDidBecomeActive(_ scene: UIScene) {
        DimUnDim.shared.dim()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        DimUnDim.shared.unDim()
    }
}

