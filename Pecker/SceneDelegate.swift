//
//  SceneDelegate.swift
//  Pecker
//
//  Created by elanchou on 2024/12/1.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        // 创建启动动画视图
        let launchScreen = UIView(frame: window.bounds)
        launchScreen.backgroundColor = .systemBackground
        
        let logoImageView = UIImageView(image: UIImage(named: "AppLogo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        launchScreen.addSubview(logoImageView)
        
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: launchScreen.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: launchScreen.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        window.rootViewController = MainTabBarController()
        window.makeKeyAndVisible()
        self.window = window
        
        // 添加启动屏幕
        window.addSubview(launchScreen)
        
        // 执行动画
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut) {
            logoImageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                launchScreen.alpha = 0
            } completion: { _ in
                launchScreen.removeFromSuperview()
            }
        }
        
        // 显示今日总结
        if TodaySummaryManager.shared.shouldShowSummary() {
            let summaryVC = TodaySummaryViewController()
            window.rootViewController?.present(summaryVC, animated: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            AIAssistantManager.shared.setup(in: window)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

