import UIKit

/// UIKit consults this method whenever it needs the set of supported
/// orientations. Returning a dynamic mask is the supported way to lock or
/// unlock rotation at runtime (the Info.plist list is only the default).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationController.shared.mask
    }
}
