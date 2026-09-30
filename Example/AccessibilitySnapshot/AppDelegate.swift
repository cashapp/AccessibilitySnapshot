import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // The window is set up by `SceneDelegate`, since apps built with the iOS 27 SDK must adopt the scene life cycle.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: - Menus

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        MenuController.shared.buildMenu(with: builder)
    }

    // MARK: - Menu Actions

    @objc func handleKeyboardShortcut(_ sender: UIKeyCommand) {
        print("Keyboard shortcut activated: \(sender.title)")
    }
}
