import Foundation

public enum TDHTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public struct TDParameterEncoding: OptionSet {
  public static let json = TDParameterEncoding(rawValue: 1 << 0)
  public static let queryString = TDParameterEncoding(rawValue: 1 << 1)
  public static let httpBody = TDParameterEncoding(rawValue: 1 << 2)

  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
}

public typealias TDHTTPHeaders = [String: String]
public typealias TDHTTPPayload = [String: Any]

public enum TDAuthenticationMethod {
  case none
  case oauth
}

private extension NSLocale {
  static var currentLanguageCode: String {
    let locale = Self.preferredLanguages.first?.components(separatedBy: "-").first
    return locale ?? "en"
  }
}

public class TDNetworkRequest {
  public let endpoint: String
  public let method: TDHTTPMethod
  public let parameterEncoding: TDParameterEncoding
  public let httpHeaders: TDHTTPHeaders
  public let authenticationMethod: TDAuthenticationMethod
  public let httpPayload: TDHTTPPayload?
  public let data: Data?

  private static var defaultHeaders: TDHTTPHeaders {
    return [
      "Accept-Language": NSLocale.currentLanguageCode,
      "Content-Language": NSLocale.currentLanguageCode,
      "X-Local-Timezone": TimeZone.autoupdatingCurrent.identifier
    ]
  }

  public init(
    endpoint: String,
    method: TDHTTPMethod,
    parameterEncoding: TDParameterEncoding = [.json],
    httpHeaders: TDHTTPHeaders = [:],
    authenticationMethod: TDAuthenticationMethod = .oauth,
    httpPayload: TDHTTPPayload? = nil,
    data: Data? = nil
  ) {
    self.endpoint = endpoint
    self.method = method
    self.parameterEncoding = parameterEncoding
    self.httpHeaders = httpHeaders
    self.authenticationMethod = authenticationMethod
    self.httpPayload = httpPayload
    self.data = data
  }

  public func buildURLRequest() throws -> URLRequest {
    let requestUrl = try self.buildURL()

    var urlRequest: URLRequest = URLRequest(url: requestUrl)
    urlRequest.httpMethod = self.method.rawValue

    // Merge default headers with custom provided ones. In case of conflict, keys in custom header dictionary are used.
    Self.defaultHeaders.merging(self.httpHeaders, uniquingKeysWith: { return $1 }).forEach {
      urlRequest.addValue($1, forHTTPHeaderField: $0)
    }

    if self.parameterEncoding.contains(.json) {
      urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
      urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    if let data = self.data {
      urlRequest.httpBody = data
    } else {
      urlRequest.httpBody = try self.buildBody()
    }

    return urlRequest
  }

  /// Creates an URL from the provided endpoint and HTTP parameters.
  public func buildURL() throws -> URL {
    guard var components = URLComponents(string: self.endpoint) else {
      throw TDError.invalidURL("Failed to create components from \(self.endpoint)")
    }

    if let payload = self.httpPayload, self.parameterEncoding.contains(.queryString) {
      if components.queryItems == nil {
        components.queryItems = []
      }
      payload.forEach { parameter in
        components.queryItems?.append(URLQueryItem(name: "\(parameter.key)", value: "\(parameter.value)"))
      }
    }

    guard let requestUrl = components.url else {
      throw TDError.invalidURL("The URL of \(components) is not available")
    }
    return requestUrl
  }

  public func buildBody() throws -> Data? {
    guard let httpPayload = self.httpPayload else { return nil }

    if self.parameterEncoding.contains(.json) {
      guard JSONSerialization.isValidJSONObject(httpPayload) == true else {
        throw TDError.invalidJSONPayload(httpPayload)
      }

      let jsonData = try JSONSerialization.data(withJSONObject: httpPayload)
      return jsonData
    } else if self.parameterEncoding.contains(.httpBody) {
      let mappedPaylaod = httpPayload
        .map { arg in
          let (key, value) = arg
          let encodedValue = "\(value)".percentEncoded
          return "\(key)=\(encodedValue)"
        }
        .joined(separator: "&")

      return mappedPaylaod.data(using: String.Encoding.utf8)
    } else {
      return nil
    }
  }
}

extension String {
  var percentEncoded: String {
    var characterSet = CharacterSet.alphanumerics
    characterSet.insert(charactersIn: "-._* ")

    return self
      .addingPercentEncoding(withAllowedCharacters: characterSet)!
      .replacingOccurrences(of: " ", with: "%20")
      .replacingOccurrences(of: "+", with: "%2B", options: [], range: nil)
  }
}
