//
//  UUID+bytes.swift
//  Demo App
//
//  Created by Nicolas Da Mutten on 16.05.21.
//

import Foundation

extension UUID {
	var bytes: [UInt8] {
		[
			self.uuid.0,
			self.uuid.1,
			self.uuid.2,
			self.uuid.3,
			self.uuid.4,
			self.uuid.5,
			self.uuid.6,
			self.uuid.7,
			self.uuid.8,
			self.uuid.9,
			self.uuid.10,
			self.uuid.11,
			self.uuid.12,
			self.uuid.13,
			self.uuid.14,
			self.uuid.15,
		]
	}
}
