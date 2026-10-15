import UIKit
import Observation

/// Single source of truth for allowed orientations.
///
/// - When `isLocked` is `false`, the app follows the `UISupportedInterfaceOrientations`
///   lists declared in `Info.plist`.
/// - When `isLocked` is `true`, the mask below is used instead (e.g. force portrait).
@Observable
final class OrientationController {
    static let shared = OrientationController()

    /// Mirror of the Info.plist default for iPhone.
    static let plistDefault: UIInterfaceOrientationMask = [.portrait, .landscapeLeft, .landscapeRight]

    var isLocked = false
    var lockedMask: UIInterfaceOrientationMask = .portrait

    var mask: UIInterfaceOrientationMask {
        isLocked ? lockedMask : Self.plistDefault
    }

    /// Tells the active scene to re-evaluate supported orientations and, if the
    /// device is already held in an allowed orientation, rotate to it immediately.
    func requestRotationUpdate() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else { return }

        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}
