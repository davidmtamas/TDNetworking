import Foundation

public protocol TDURLRequestProcessorProtocol {
  func process(request: URLRequest) async throws -> TDNetworkResponse
}

public final class TDURLRequestProcessor: TDURLRequestProcessorProtocol {
  private let urlSession: URLSession

  public init(urlSession: URLSession) {
    self.urlSession = urlSession
  }

  public func process(request: URLRequest) async throws -> TDNetworkResponse {
    var (data, response): (Data, URLResponse)
    if #available(iOS 15.0, macOS 12.0, *) {
      (data, response) = try await self.urlSession.data(for: request)
    } else {
      (data, response) = try await self.urlSession.dataiOS14(for: request)
    }
    guard let response = response as? HTTPURLResponse else {
      // TODO: create error for this case
      throw TDError.invalidResponse(statusCode: 500, body: nil)
    }
    return TDNetworkResponse(response, data: data)
  }
}


private extension URLSession {
  func dataiOS14(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
    try await withCheckedThrowingContinuation { continuation in
      let task = self.dataTask(with: request) { data, response, error in
        guard let data = data, let response = response else {
          // TODO: create error for this case
          let error = TDError.invalidResponse(statusCode: 500, body: nil)
          return continuation.resume(throwing: error)
        }

        continuation.resume(returning: (data, response))
      }

      task.resume()
    }
  }
}
