import Foundation

public protocol TDNetworkManagerProtocol {
  var requestProcessor: TDURLRequestProcessorProtocol { get }
  var authSessionProvider: TDAuthSessionManagerProtocol { get }

  func send<T: Decodable>(request: TDNetworkRequest) async throws -> T
  func send<T: Decodable>(request: TDNetworkRequest, decoder: JSONDecoder) async throws -> T

  @discardableResult
  func send(request: TDNetworkRequest) async throws -> TDNetworkResponse
}

public class TDNetworkManager: TDNetworkManagerProtocol {
  public let requestProcessor: TDURLRequestProcessorProtocol
  public let authSessionProvider: TDAuthSessionManagerProtocol

  public init(requestProcessor: TDURLRequestProcessorProtocol, authSessionProvider: TDAuthSessionManagerProtocol) {
    self.requestProcessor = requestProcessor
    self.authSessionProvider = authSessionProvider
  }

  public func send<T: Decodable>(request: TDNetworkRequest) async throws -> T {
    return try await self.send(request: request, decoder: JSONDecoder())
  }

  public func send<T: Decodable>(request: TDNetworkRequest, decoder: JSONDecoder) async throws -> T {
    let networkResponse = try await self.send(request: request)
    
    return try decoder.decode(T.self, from: networkResponse.data)
  }

  @discardableResult
  public func send(request: TDNetworkRequest) async throws -> TDNetworkResponse {
    return try await self.send(request: request, retryUnauthorizedRequest: true)
  }
}

// MARK: - Private methods
private extension TDNetworkManager {
  func send(request: TDNetworkRequest, retryUnauthorizedRequest: Bool) async throws -> TDNetworkResponse {
    let urlRequest = try await self.prepareURLRequest(from: request)


    let networkResponse = try await self.requestProcessor.process(request: urlRequest)

    try Task.checkCancellation()

    // If our request was unauthorized and we are allowed to retry it, we first try to refresh the access token
    // and afterwards retry the original request by recursively re-calling this method.
    if networkResponse.status == .unauthorized, retryUnauthorizedRequest == true {
      try await self.authSessionProvider.authenticate(credentials: TDTokenRefreshCredentials())
      try Task.checkCancellation()
      return try await self.send(request: request, retryUnauthorizedRequest: false)
    }

    guard networkResponse.urlResponse.isSuccessful else {
      throw networkResponse.mapToApiError
    }

    return networkResponse
  }

  func prepareURLRequest(from request: TDNetworkRequest) async throws -> URLRequest {
    var urlRequest = try request.buildURLRequest()

    if request.authenticationMethod == .oauth {
      let accessToken = try await self.authSessionProvider.validAccessToken()
      urlRequest.addValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
    }

    return urlRequest
  }
}
