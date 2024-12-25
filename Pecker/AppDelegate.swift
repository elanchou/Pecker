//
//  AppDelegate.swift
//  Pecker
//
//  Created by elanchou on 2024/12/1.
//

import UIKit
import RealmSwift
import Kingfisher

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 设置默认语言
        if UserDefaults.standard.string(forKey: "app_language") == nil {
            // 获取系统语言
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            let language: Language = preferredLanguage.contains("zh") ? .simplifiedChinese : .english
            LocalizationManager.shared.setLanguage(language)
        }
        
        setupAppearance()
        // 配置 Realm
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // 在这里处理数据迁移
                }
            }
        )
        Realm.Configuration.defaultConfiguration = config
        
        // 配置 Kingfisher
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024 // 300MB
        cache.diskStorage.config.sizeLimit = 1000 * 1024 * 1024 // 1GB
        
        KingfisherManager.shared.downloader.downloadTimeout = 15.0 // 15秒超时
        
        return true
    }

    private func setupAppearance() {
        // 导航栏外观
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = AppTheme.Navigation.barTint
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: AppTheme.Text.title]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: AppTheme.Text.title]
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().tintColor = AppTheme.Navigation.tint
        
        // 标签栏外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = AppTheme.Navigation.barTint
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = AppTheme.TabBar.tint
        UITabBar.appearance().unselectedItemTintColor = AppTheme.TabBar.unselectedTint
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

