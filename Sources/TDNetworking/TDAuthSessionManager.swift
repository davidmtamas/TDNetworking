import Foundation

public protocol TDCredentials { }

public struct TDTokenRefreshCredentials: TDCredentials { }

public protocol TDAuthSessionManagerProtocol: Actor {
  var requestProcessor: TDURLRequestProcessorProtocol { get }
  var secureStorage: TDSecureStorageManagerProtocol { get }
  var authSessionStateHolder: TDAuthSessionStateHolder { get }

  func validAccessToken() async throws -> String

  @discardableResult
  func authenticate(credentials: TDCredentials) async throws -> String
}
