import Foundation
import Combine

public enum TDAuthState {
  case none
  case authenticated
}

public actor TDAuthSessionStateHolder {
  private var authState = CurrentValueSubject<TDAuthState, Never>(.none)

  public var authStatePublisher: AnyPublisher<TDAuthState, Never> {
    return self.authState
      .dropFirst()
      .receive(on: RunLoop.main)
      .eraseToAnyPublisher()
  }

  public func setAuthState(authState: TDAuthState) {
    self.authState.send(authState)
  }
}
