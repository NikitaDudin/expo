// Copyright 2015-present 650 Industries. All rights reserved.

import Foundation

@objc
public class EXDevLauncherUncaughtExceptionHandler: NSObject {
  static private var defaultHandler: (@convention(c) (NSException) -> Swift.Void)?

  @objc
  public static var isInstalled: Bool = false {
    willSet {
      if isInstalled != newValue {
        if newValue {
          installHandler()
        } else {
          uninstallHandler()
        }
      }
    }
  }

  static func installHandler() {
    defaultHandler = NSGetUncaughtExceptionHandler()

    NSSetUncaughtExceptionHandler { exception in
      NSLog("DevLauncher tries to handle uncaught exception: %@", exception)
      NSLog("Stack Trace: %@", exception.callStackSymbols)
      
      EXDevLauncherUncaughtExceptionHandler.tryToSendExceptionToBundler(exception: exception)
      EXDevLauncherUncaughtExceptionHandler.defaultHandler?(exception)
    }
  }

  static func uninstallHandler() {
    NSSetUncaughtExceptionHandler(defaultHandler)
  }
  
  
  static func tryToSendExceptionToBundler(exception: NSException) {
    let controller = EXDevLauncherController.sharedInstance()
    if (controller.isAppRunning()) {
      guard let url = getLogsUrl(controller) else {
        return
      }
      
      let logsManager = EXDevLauncherRemoteLogsManager(withUrl: url)
      logsManager.deferError(message: "Your app just crashed. See the error below.")
      logsManager.deferError(exception: exception)
      logsManager.sendSync()
    }
  }
  
  static func getLogsUrl(_ controller: EXDevLauncherController) -> URL? {
    let logsUrlFromManifest = controller.appManifest()?.rawManifestJSON()["logsUrl"] as? String
    if (logsUrlFromManifest != nil) {
      return URL.init(string: logsUrlFromManifest!)
    }
    
    guard let appUrl = controller.appBridge?.bundleURL else {
      return nil
    }
    
    return URL.init(string: "logs", relativeTo: appUrl)
  }
}
