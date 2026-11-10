import SwiftUI
import UIKit

@main
struct SnakeIOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            SnakeGameView()
        }
    }
}

/// Força o modo retrato no iPhone. O xtool já define isso no Info.plist
/// padrão (UISupportedInterfaceOrientations = portrait); este delegate é uma
/// camada extra de garantia.
private final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}
