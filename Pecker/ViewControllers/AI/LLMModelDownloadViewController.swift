//
//  LLMModelDownloadViewController.swift
//  Pecker
//
//  Created by elanchou on 2025/2/9.
//

import Foundation
import UIKit
import SwiftUI

class LLMModelDownloadViewController: UIViewController {
    
    private var appManager = AppManager()
    private var llm = LLMEvaluator()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
    }
    
    func setupUI() {
        
//        let swiftUIView = OnboardingInstallModelView(showOnboarding: .constant(true))
//            .environment(llm)
//            .environmentObject(appManager)
        
        let swiftUIView = ModelsSettingsView()
            .environment(llm)
            .environmentObject(appManager)
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
}
