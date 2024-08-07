#if os(Linux)
	import Foundation
	public extension URL {
		static var homeDirectory: URL {
			let home = ProcessInfo.processInfo.environment["HOME"]!
			return URL(fileURLWithPath: home)
		}

		func appending(path: String) -> URL {
			self.appendingPathComponent(path)
		}
	}
#endif


