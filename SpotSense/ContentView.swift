//
//  ContentView.swift
//  OverflowAreaBeaconRef
//
//  Created by David G. Young on 8/22/20.
//  Copyright © 2020 davidgyoungtech. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var beaconStateModel = BeaconStateModel.shared
    @ObservedObject var userData = UserData.shared
    @State private var userId: String = ""
    @State private var savedUserId: String = UserDefaults.standard.string(forKey: "savedUserId") ?? ""
    @State private var errorMessage: String?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    var body: some View {
       VStack {
           Text("This device major: "+String(beaconStateModel.myMajor,radix:16)+" minor: "+String(beaconStateModel.myMinor,radix:16))
            Text("Error condition: \(beaconStateModel.error ?? "None known")")
            Spacer()
            //受信に関する表示は削除
            //Text("I detect \(beaconStateModel.beacons.count) beacons")
            //List(beaconStateModel.beacons) { beaconViewItem in
            //    Text(beaconViewItem.beaconString)
            //}.id(UUID())
           Text("OA番号を入力してください")
               .font(.headline)

           TextField("OA番号", text: $userId)
               .textFieldStyle(RoundedBorderTextFieldStyle())
               .padding()
               .keyboardType(.numberPad)  // 数字キーボードを表示する設定
           Button(action: {
               validateUserId()
//               if isValidNumber(input: userId) {
//                   // 入力が数値である場合
//                   errorMessage = nil
//                   // 正常に処理を進める（IDを保存する）
//                   //UserDefaults.standard.set(userId, forKey: "savedUserId")
//                   UserDefaults.standard.set(userData.userId, forKey: "savedUserId")
//                   savedUserId = userId
//                   UserData.shared.userId = userId
//                } else {
//                   // 入力が無効な場合
//                   errorMessage = "入力が無効です。数値のみを入力してください。"
//                }
           }) {
               Text("OA番号を保存")
                   .foregroundColor(.white)
                   .padding()
                   .background(Color.blue)
                   .cornerRadius(10)
           }
           
           if let errorMessage = errorMessage {
               Text(errorMessage)
                   .foregroundColor(.red)
                   .padding()
           }

           if !savedUserId.isEmpty {
               //Text("保存されたID: \(savedUserId)")
               Text("保存されたOA番号: \(userData.userId)")
           }
           
        }
        .padding()
        .onAppear {
            // アプリ起動時にUserDefaultsから保存されたIDを取得する
            if let storedId = UserDefaults.standard.string(forKey: "savedUserId") {
                        //savedUserId = storedId
                        print("storedId="+storedId)
                        userData.userId = storedId
                    }
                appDelegate.viewDidAppear()
            }
    }
    // 入力された文字列が7桁の整数であるかを確認する関数
    func isValidNumber(input: String) -> Bool {
        return !input.isEmpty && input.allSatisfy { $0.isNumber }
    }
    private func validateUserId() {
        // 入力されたIDが7桁の数値であるかをチェック
        if userId.count == 7, let _ = Int(userId), Int(userId) != nil {
            errorMessage = nil
            // 正しい場合、さらに処理を続行する
            print("ユーザーIDが正しい形式です: \(userId)")
            UserDefaults.standard.set(userId, forKey: "savedUserId")
            savedUserId = userId
            UserData.shared.userId = userId
            userId = ""
            hideKeyboard() // キーボードを閉じる
            if let storedId = UserDefaults.standard.string(forKey: "savedUserId") {
                print("saved:"+storedId)
            }
        } else {
            errorMessage = "7桁の数値を入力してください"
        }
    }
    private func hideKeyboard() {
        // キーボードを閉じる
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct BeaconViewItem: Identifiable {
  var id = UUID()
  var beaconString: String
}

class BeaconStateModel: ObservableObject {
    static let shared = BeaconStateModel()
    private init() {
        
    }
    @Published var beacons: [BeaconViewItem] = []
    @Published var myMajor = 0
    @Published var myMinor = 0
    @Published var error: String? = nil
}

class UserData: ObservableObject {
    @Published var userId: String = ""
    static let shared = UserData() // シングルトンインスタンス
}
