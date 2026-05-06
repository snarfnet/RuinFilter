import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct RuinFilterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if AppRuntime.showsAds {
                        GADMobileAds.sharedInstance().start(completionHandler: nil)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    if AppRuntime.showsAds {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            ATTrackingManager.requestTrackingAuthorization { _ in }
                        }
                    }
                }
        }
    }
}
