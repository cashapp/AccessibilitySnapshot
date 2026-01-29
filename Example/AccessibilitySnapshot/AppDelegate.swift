import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window

        let rootViewController = RootViewController()

        let navigationController = UINavigationController(rootViewController: rootViewController)
        window.rootViewController = navigationController

        window.makeKeyAndVisible()

        return true
    }
}
