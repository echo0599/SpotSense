//
//  AppDelegate.swift
//  OverflowAreaBeaconRef
//
//  Created by David G. Young on 8/22/20.
//  Copyright © 2020 davidgyoungtech. All rights reserved.
//

import UIKit
import Combine
import CoreBluetooth
import CoreLocation


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OverflowDetectorDelegate {
    
    let fusedBeaconManager = FusedBeaconManager.shared
    private var cancellable: AnyCancellable?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        fusedBeaconManager.locationManager.requestAlwaysAuthorization()

        // 通知は使用しないが、他の部分の修正が多くなるので登録は残しておく
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            self.fusedBeaconManager.updateAuthWarnings()

            if let error = error {
                NSLog("error: \(error)")
            }
            
        }
        // userIdの変更を監視
        cancellable = UserData.shared.$userId.sink { newUserId in
            print("AppDelegate: userIdが更新されました: \(newUserId)")
            // ここで任意の処理を実行
            self.handleUserIdChange(newUserId)
        }

        // start ranging beacons to force BLE scans.  If this is not done, delivery of overflow area advertisements will not be made when the // app is not in the foreground.  Enabling beacon ranging appears to unlock this background delivery, at least when the screen is on.
//        let major = Int.random(in: 1..<10000)
//        let minor = Int.random(in: 1..<10000)
//        BeaconStateModel.shared.myMajor = major
//        BeaconStateModel.shared.myMinor = minor
//        _ = fusedBeaconManager.stopTx()
//        fusedBeaconManager.configure(iBeaconUuid: UUID(uuidString: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6")!, overflowMatchingByte: 0xaa,  major: UInt16(major), minor: UInt16(minor), measuredPower: -59)
//        _ = fusedBeaconManager.startScanning(delegate: self)
//        _ = fusedBeaconManager.startTx()
//
//        fusedBeaconManager.updateAuthWarnings()
//        BeaconStateModel.shared.error = fusedBeaconManager.errors.first
//        print("My major: "+String(major,radix:16)+" minor: "+String(minor,radix: 16))

        return true
    }
    func viewDidAppear() {
        print("Viewが表示されました。処理を開始します。")
        let userId = UserData.shared.userId
        print("現在のユーザーIDは: \(userId)")
        // ここで任意の処理を実行
    }
    func handleUserIdChange(_ newUserId: String) {
        // userIdが変更されたときの処理
        print("AppDelegateで処理を実行します。新しいuserId: \(newUserId)")
        // newUserIdは7桁の数字文字列
        if let major = Int(newUserId.prefix(3)) {
            print("majorの変換成功: \(major)")  // 変換されたIntの数値を表示
            BeaconStateModel.shared.myMajor = major
        } else {
            print("majorの変換失敗: 入力が無効です")
            return
        }
        if let minor = Int(newUserId.suffix(4)) {
            print("minorの変換成功: \(minor)")  // 変換されたIntの数値を表示
            BeaconStateModel.shared.myMinor = minor
        } else {
            print("minorの変換失敗: 入力が無効です")
            return
        }
        _ = fusedBeaconManager.stopTx()
        fusedBeaconManager.configure(iBeaconUuid: UUID(uuidString: "2F234454-CF6D-4A0F-ADF2-F4911BA9FFA6")!, overflowMatchingByte: 0xaa,  major: UInt16(BeaconStateModel.shared.myMajor), minor: UInt16(BeaconStateModel.shared.myMinor), measuredPower: -59)
        // _ = fusedBeaconManager.startScanning(delegate: self)
        _ = fusedBeaconManager.startTx()

        fusedBeaconManager.updateAuthWarnings()
        BeaconStateModel.shared.error = fusedBeaconManager.errors.first
        print("My major: "+String(BeaconStateModel.shared.myMajor,radix:16)+" minor: "+String(BeaconStateModel.shared.myMinor,radix: 16))
    }
    
    func didDetectBeacon(type: String, major: UInt16, minor: UInt16, rssi: Int, proximityUuid: UUID?, distance: Double?){
        //NSLog("Detected beacon major: \(major) minor: \(minor) of type: \(type)")
        NSLog("Detected beacon major: " + String(major,radix:16) + " minor: " + String(minor, radix:16) + " of type: \(type)")
        updateBeaconListView(type: type, major: major, minor: minor, rssi: rssi, proximityUuid: proximityUuid, distance: distance)
    }
    
    func updateBeaconListView(type: String, major: UInt16, minor: UInt16, rssi: Int, proximityUuid: UUID?, distance: Double?){

        DispatchQueue.main.async {
            var beaconViewItems = BeaconStateModel.shared.beacons
            //let majorMinor = "major: \(major), minor:\(minor)"
            let majorMinor = "major: "+String(major,radix:16)+", minor: "+String(minor,radix:16)
            let beaconString = "\(majorMinor), rssi: \(rssi) (\(type))"
            let beaconViewItem = BeaconViewItem(beaconString: beaconString)
            var updatedExisting = false
            var index = 0
            for existingBeaconViewItem in beaconViewItems {
                if existingBeaconViewItem.beaconString.contains(majorMinor) {
                    beaconViewItems[index] = beaconViewItem
                    updatedExisting = true
                    break
                }
                index += 1
            }
            if (!updatedExisting) {
                beaconViewItems.append(beaconViewItem)
            }
            BeaconStateModel.shared.error = self.fusedBeaconManager.errors.first
            BeaconStateModel.shared.beacons = beaconViewItems
        }
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
