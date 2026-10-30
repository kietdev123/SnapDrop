import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SnapDropClipboard") {
      ClipboardChannel.register(messenger: registrar.messenger())
    }
  }
}

enum ClipboardChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "snapdrop/clipboard", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let pb = UIPasteboard.general
      switch call.method {
      case "peek":
        // Bước 1: hasImages + changeCount không đọc nội dung → không hiện hộp thoại "Cho phép dán".
        guard pb.hasImages else {
          result(["hasImage": false])
          return
        }
        result(["hasImage": true, "id": "ios-\(pb.changeCount)"])
      case "readImage":
        // Chỉ đọc ảnh thật khi người dùng bấm.
        guard let image = pb.image, let png = image.pngData() else {
          result(nil)
          return
        }
        result(FlutterStandardTypedData(bytes: png))
      case "writeTestImage":
        guard let data = (call.arguments as? FlutterStandardTypedData)?.data, let image = UIImage(data: data) else {
          result(FlutterError(code: "clipboard", message: "Ảnh không hợp lệ", details: nil))
          return
        }
        pb.image = image
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
