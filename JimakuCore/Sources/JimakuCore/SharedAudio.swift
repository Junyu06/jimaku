import Foundation

/// Where the app and the broadcast extension find the audio ring they share.
public enum SharedAudio {
    /// Info.plist key that holds the App Group identifier. Both targets set it from
    /// the same build setting, so they always agree.
    public static let appGroupInfoKey = "JimakuAppGroup"

    public static let ringFileName = "audio-ring.bin"

    /// The App Group identifier of the running bundle, if configured.
    public static var appGroup: String? {
        Bundle.main.object(forInfoDictionaryKey: appGroupInfoKey) as? String
    }

    /// The ring file inside the shared App Group container. Nil when the bundle has
    /// no App Group, or the system does not grant access to it.
    public static func ringURL(appGroup: String? = SharedAudio.appGroup) -> URL? {
        guard let appGroup, !appGroup.isEmpty else { return nil }
        return FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent(ringFileName)
    }
}
