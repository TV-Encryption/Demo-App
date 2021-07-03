//
//  KeyManager.swift
//  Demo App
//
//  Created by Nicolas Da Mutten on 22.04.21.
//

import AVKit
import Combine

protocol KeyManager {
	static var customScheme: String { get }
	func handle(_ keyRequest: AVAssetResourceLoadingRequest)
}

class ZHAWKeyManager: KeyManager {
	public enum Error: Swift.Error {
		case noURL
		case invalidURL
		case invalidResponse
		case loadingFailed
		case authFailed
		case noAppCert
	}

	public static let customScheme = "skd"
	static let jsonEncoder = JSONEncoder()
	static let jsonDecoder = JSONDecoder()
	static let keyServerURL = URL(string: BuildConfiguration.fairplayServerURL)!
	static let authServerURL = URL(string: BuildConfiguration.authServerURL)!
	var authToken: String?
	var urlSession: URLSession
	var requests = [AnyCancellable]()

	init(authToken: String? = nil, urlSession: URLSession = URLSession(configuration: .default)) {
		self.authToken = authToken
		self.urlSession = urlSession
	}

	func getAuthToken(completion: @escaping (Bool) -> Void) {
		let urlRequest = URLRequest(url: Self.authServerURL)
		self.execute(urlRequest) { result in
			switch result {
				case let .success(data):
					// TBD: decode response and store token
					completion(true)
				case .failure:
					completion(false)
			}
		}
	}

	func execute(
		_ request: URLRequest,
		completion: @escaping (Result<(data: Data, response: URLResponse), Swift.Error>) -> Void
	) {
		var urlRequest = request

		if let token = self.authToken {
			urlRequest.addValue("Token \(token)", forHTTPHeaderField: "Authorization")
		}

		self.urlSession.dataTaskPublisher(for: urlRequest)
			// Catch unauthorized responses and try afain after getting auth
			.flatMap { result -> AnyPublisher<Result<(data: Data, response: URLResponse), Swift.Error>, Never> in
				guard let response = result.response as? HTTPURLResponse else {
					return Just(.failure(Error.invalidResponse)).eraseToAnyPublisher()
				}
				guard response.statusCode != 403 else {
					return Future { promise in
						self.getAuthToken { success in
							guard success else {
								// Future promise was a success, but not it's result
								promise(.success(.failure(Error.authFailed)))
								return
							}
							self.execute(request) { result in
								promise(.success(result))
							}
						}
					}.flatMap { response in
						Just(response)
					}.eraseToAnyPublisher()
				}
				guard (200..<300).contains(response.statusCode) else {
					return Just(.failure(Error.loadingFailed)).eraseToAnyPublisher()
				}
				return Just(.success(result)).eraseToAnyPublisher()
			}
			.catch { Just(.failure($0)) }
			.sinkAndStoreUntilCompleted(receiveValue: completion)
	}

	func requestKey(
		at url: URL,
		with requestBody: KeyRequestBody,
		completion: @escaping (Result<KeyResponseBody, Swift.Error>) -> Void
	) {
		var request = URLRequest(url: url)
		request.httpMethod = "POST"

		do {
			let body = try Self.jsonEncoder.encode(requestBody)
			request.httpBody = body
			request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		} catch {
			completion(.failure(error))
			return
		}

		self.execute(request) { result in
			completion(result.flatMap { (data: Data, response: URLResponse) in
				guard let _ = response as? HTTPURLResponse else {
					return .failure(Error.invalidResponse)
				}

				do {
					let responseBody = try Self.jsonDecoder.decode(KeyResponseBody.self, from: data)
					return .success(responseBody)
				} catch {
					return .failure(error)
				}
			})
		}
	}

	func getKey(with key_ref: UUID, and spc: Data, completion: @escaping (Result<Data, Swift.Error>) -> Void) {
		let keyServerURL = Self.keyServerURL
		let requestBody = KeyRequestBody(key_ref: key_ref, spc: spc.base64EncodedString())
		self.requestKey(at: keyServerURL, with: requestBody) { result in
			switch result {
				case let .failure(error):
					completion(.failure(error))
				case let .success(responseBody):
					guard let ckc = Data(base64Encoded: responseBody.ckc) else {
						completion(.failure(Error.invalidResponse))
						return
					}
					completion(.success(ckc))
			}
		}
	}

	public func handle(_ keyRequest: AVAssetResourceLoadingRequest) {
		guard let url = keyRequest.request.url else {
			keyRequest.finishLoading(with: Error.noURL)
			return
		}
		guard let host = url.host, let key_ref = UUID(uuidString: host) else {
			keyRequest.finishLoading(with: Error.invalidURL)
			return
		}

		do {
			guard let cert = NSDataAsset(name: "cert") else {
				keyRequest.finishLoading(with: Error.noAppCert)
				assert(false, "No App Cert found in Asset Catalog!")
				return
			}

			let spc = try keyRequest.streamingContentKeyRequestData(
				forApp: cert.data,
				contentIdentifier: Data(key_ref.bytes),
				options: nil
			)
			self.getKey(with: key_ref, and: spc) { result in
				switch result {
					case let .success(data):
						keyRequest.dataRequest?.respond(with: data)
						keyRequest.finishLoading()
					case let .failure(error):
						keyRequest.finishLoading(with: error)
				}
			}
		} catch {
			keyRequest.finishLoading(with: error)
		}
	}

	struct KeyRequestBody: Encodable {
		var key_ref: UUID
		var spc: String
	}

	struct KeyResponseBody: Decodable {
		var ckc: String
	}
}
