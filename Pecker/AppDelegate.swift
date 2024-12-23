//
//  AppDelegate.swift
//  Pecker
//
//  Created by elanchou on 2024/12/1.
//

import UIKit
import RealmSwift
import SDWebImage

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupAppearance()
        // 配置 Realm
        let config = Realm.Configuration(
            schemaVersion: 2,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    migration.enumerateObjects(ofType: Content.className()) { oldObject, newObject in
                        newObject!["isDeleted"] = false
                    }
                }
            })
        
        Realm.Configuration.defaultConfiguration = config
        
        if let fileURL = config.fileURL {
            print("Realm 数据库位置: \(fileURL)")
        }
        
        // 配置 SDWebImage
        SDImageCache.shared.config.maxMemoryCost = 100 * 1024 * 1024 // 100MB 内存缓存
        SDImageCache.shared.config.maxDiskAge = 7 * 24 * 60 * 60 // 7天磁盘缓存
        SDImageCache.shared.config.maxDiskSize = 500 * 1024 * 1024 // 500MB 磁盘缓存上限
        SDWebImageDownloader.shared.config.downloadTimeout = 15 // 15秒超时
        SDWebImageDownloader.shared.config.maxConcurrentDownloads = 6 // 最大并发下载数
        SDWebImageDownloader.shared.config.executionOrder = .lifoExecutionOrder // 后进先出顺序
        
        // 配置压缩和缓存
        SDImageCache.shared.config.shouldCacheImagesInMemory = true
        SDImageCache.shared.config.shouldUseWeakMemoryCache = true
        
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

