//
//  ViewController.swift
//  Demo App
//
//  Created by Nicolas Da Mutten on 09.04.21.
//

import AVKit
import UIKit

class ViewController: UIViewController {
	@IBOutlet var urlField: UITextField!

	var keyManager: KeyManager!
	var playerObserver: NSKeyValueObservation!
	var playerItemObserver: NSKeyValueObservation!

	// MARK: - View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		self.keyManager = ZHAWKeyManager()
	}

	// MARK: - Actions

	@IBAction func start(_: UIButton) {
		guard let text = urlField.text, let url = URL(string: text) else {
			return
		}

		self.launchPlayer(for: url)
	}

	// MARK: - Private methods

	func launchPlayer(for url: URL) {
		let playerItem = self.preparePlayerItem(for: url)
		// Create an AVPlayer, passing it the HTTP Live Streaming URL.
		let player = AVPlayer(playerItem: playerItem)

		// Needed for Fairplay over Airplay
		player.usesExternalPlaybackWhileExternalScreenIsActive = true

		// Create a new AVPlayerViewController and pass it a reference to the player.
		let controller = AVPlayerViewController()
		controller.player = player

		// Modally present the player and call the player's play() method when complete.
		self.present(controller, animated: true) {
			player.play()
		}
	}

	func preparePlayerItem(for url: URL) -> AVPlayerItem {
		let asset = AVURLAsset(url: url)

		let queue = DispatchQueue.global(qos: .userInitiated)
		asset.resourceLoader.setDelegate(self, queue: queue)

		let playerItem = AVPlayerItem(asset: asset)
		return playerItem
	}
}

extension ViewController: AVAssetResourceLoaderDelegate {
	func resourceLoader(
		_: AVAssetResourceLoader,
		shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
	) -> Bool {
		guard let scheme = loadingRequest.request.url?.scheme else {
			return false
		}

		if scheme == type(of: self.keyManager).customScheme {
			DispatchQueue.global(qos: .userInitiated).async {
				self.keyManager.handle(loadingRequest)
			}

			return true
		}

		return false
	}
}
