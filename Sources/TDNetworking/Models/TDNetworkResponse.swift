import Foundation

public enum TDError: Error {
  /// Thrown when validating the server response failed.

  case invalidResponse(statusCode: Int, body: String?)

  case invalidURL(String)

  case invalidJSONPayload(TDHTTPPayload)

  case unauthorized
}

public struct TDNetworkResponse {

  /// The original `HTTPURLResponse` received.
  public let urlResponse: HTTPURLResponse

  /// The data received from the server.
  public let data: Data

  /// Convenience access to the `HTTPURLResponseStatus` of the
  /// `HTTPURLResponse`.
  public var status: HTTPURLResponseStatus {
    return self.urlResponse.status
  }

  /// The attribute is available if the data received from the server can be
  /// decoded as json.
  /// The type may be either `[Any]` or `[AnyHashable: Any]`, cast at will.
  public var json: Any? {
    do {
      let json = try JSONSerialization.jsonObject(with: data)
      return json
    } catch {
      //     log.verbose("Cannot decode body as JSON")
      return nil
    }
  }

  /// The body attribute is available if the data received from the server
  /// can be decoded as UTF8 text.
  public var body: String? {
    return String(data: data, encoding: String.Encoding.utf8)
  }

  public var mapToApiError: TDError {
    return .invalidResponse(statusCode: self.status.rawValue, body: String(data: self.data, encoding: .utf8))
  }

  /// Initiates and returns a new struct.
  ///
  /// - Parameters:
  ///   - urlResponse: The original HTTPURLResponse.
  ///   - data: The data received from the server.
  public init(_ urlResponse: HTTPURLResponse, data: Data) {
    self.urlResponse = urlResponse
    self.data = data
  }
}
