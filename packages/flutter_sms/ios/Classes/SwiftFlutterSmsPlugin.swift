import Flutter
import UIKit
import MessageUI

public class SwiftFlutterSmsPlugin: NSObject, FlutterPlugin, SmsHostApi, UINavigationControllerDelegate, MFMessageComposeViewControllerDelegate {
    var result: ((Result<String, Error>) -> Void)?
    var _arguments = [String: Any]()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SwiftFlutterSmsPlugin()
    SmsHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
  }

  public func sendSms(message: String, recipients: [String], completion: @escaping (Result<String, Error>) -> Void) {
    #if targetEnvironment(simulator)
      completion(.failure(PigeonError(
          code: "message_not_sent",
          message: "Cannot send message on this device!",
          details: "Cannot send SMS and MMS on a Simulator. Test on a real device."
      )))
#else
      if (MFMessageComposeViewController.canSendText()) {
          self.result = completion
          let controller = MFMessageComposeViewController()
          controller.body = message
          controller.recipients = recipients
          controller.messageComposeDelegate = self

          DispatchQueue.main.async {
              if let topVC = UIApplication.topViewController() {
                  topVC.present(controller, animated: true, completion: nil)
              } else {
                completion(.failure(PigeonError(
                  code: "no_presentation_context",
                  message: "Unable to present SMS composer.",
                  details: "No visible UIViewController found in the window hierarchy. Ensure the app has an active screen before attempting to send SMS."
                )))
              }
          }


          } else {
              completion(.failure(PigeonError(
                code: "device_not_capable",
                message: "The current device is not capable of sending text messages.",
                details: "A device may be unable to send messages if it does not support messaging or if it is not currently configured to send messages. This only applies to the ability to send text messages via iMessage, SMS, and MMS."
              )))
          }
#endif
      }

  public func canSendSms(completion: @escaping (Result<Bool, Error>) -> Void) {
    #if targetEnvironment(simulator)
      completion(.success(false))
    #else
      if (MFMessageComposeViewController.canSendText()) {
        completion(.success(true))
      } else {
        completion(.success(false))
      }
    #endif
  }

  public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    let map: [MessageComposeResult: String] = [
        MessageComposeResult.sent: "sent",
        MessageComposeResult.cancelled: "cancelled",
        MessageComposeResult.failed: "failed",
    ]
    if let callback = self.result {
        callback(.success(map[result] ?? "unknown"))
    }

     DispatchQueue.main.async {
        controller.dismiss(animated: true, completion: nil)
    }
  }
}

extension UIApplication {
    static func topViewController(
        base: UIViewController? =
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }?
                .rootViewController
    ) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }
}

 