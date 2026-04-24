//
//  BudgetAppApp.swift
//  BudgetApp
//
//  Created by Valerie on 2/18/26.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }

}

@main
struct Allocent: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
//                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
            //.onAppear for being able to tap out of keyboards & such
        }
    }
}

//extension UIApplication {
//    func addTapGestureRecognizer() {
//        guard let window = windows.first else { return }
//        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
//        tapGesture.requiresExclusiveTouchType = false
//        tapGesture.cancelsTouchesInView = false
//        tapGesture.delegate = self
//        window.addGestureRecognizer(tapGesture)
//    }
//}
//
//extension UIApplication: UIGestureRecognizerDelegate {
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true // set to `false` if you don't want to detect tap during other gestures
//    }
//}
