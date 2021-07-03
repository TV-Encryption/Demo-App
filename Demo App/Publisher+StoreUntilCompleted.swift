//
//  Publisher+StoreUntilCompleted.swift
//  Demo App
//
//  Created by Nicolas Da Mutten on 22.04.21.
//

import Combine

extension Publisher {
	func storeUntilCompleted() -> Self {
		var cancellable: Publishers.HandleEvents<Self>?
		cancellable = self.handleEvents(receiveRequest: { _ in
			cancellable = nil
		})
		return self
	}

	func sinkAndStoreUntilCompleted(
		receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void) = { _ in },
		receiveValue: @escaping ((Self.Output) -> Void) = { _ in }
	) {
		var cancellable: AnyCancellable?
		cancellable = self
			.storeUntilCompleted()
			.sink(receiveCompletion: { completion in
				receiveCompletion(completion)
				cancellable = nil
			}, receiveValue: receiveValue)
	}
}
