import Flutter
import UIKit
import FirebaseAuth

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts {
      // Phone auth reCAPTCHA callback — must reach Firebase, not go_router.
      if Auth.auth().canHandle(context.url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
