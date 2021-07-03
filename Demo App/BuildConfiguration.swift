//
//  BuildCOnfiguration.swift
//  Demo App
//
//  Created by Nicolas Da Mutten on 16.05.21.
//

import Foundation

struct BuildConfiguration {
	static var authServerURL: String { try! Self.value(for: .authServerURL) }
	static var fairplayServerURL: String { try! Self.value(for: .faripayServerURL) }

	private enum Key: String {
		case authServerURL = "AUTH_SERVER_URL"
		case faripayServerURL = "FAIRPLAY_SERVER_URL"
	}

	private init() {}

	private static func value<T: LosslessStringConvertible>(for key: Key) throws -> T {
		guard let object = Bundle.main.object(forInfoDictionaryKey: key.rawValue) else {
			throw Error.missingKey
		}

		switch object {
			case let rawString as String:
				let string = rawString.replacingOccurrences(of: "\\", with: "")
				if let value = T(string) {
					return value
				}
				throw Error.invalidValue
			case let value as T:
				return value
			default:
				throw Error.invalidValue
		}
	}

	private enum Error: Swift.Error {
		case missingKey, invalidValue
	}
}
