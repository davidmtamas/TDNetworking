import Foundation
import KeychainAccess

public enum TDSecureStorageKey: String, CaseIterable {
  case accessToken
  case accessTokenExpiryDate
  case refreshToken
}

public protocol TDSecureStorageManagerProtocol: Actor {
  func setValue(_ value: String, for key: TDSecureStorageKey) throws
  func getValue(for key: TDSecureStorageKey) throws -> String?
  func clearValues(for keys: [TDSecureStorageKey]) throws
}

public actor TDSecureStorage: TDSecureStorageManagerProtocol {
  private let keychainAccess: KeychainAccess.Keychain

  public init(keychainAccess: KeychainAccess.Keychain) {
    self.keychainAccess = keychainAccess
  }

  public func setValue(_ value: String, for key: TDSecureStorageKey) throws {
    do {
      try self.keychainAccess.set(value, key: key.rawValue)
    } catch {
      throw error
    }
  }

  public func getValue(for key: TDSecureStorageKey) throws -> String? {
    do {
      return try self.keychainAccess.getString(key.rawValue)
    } catch {
      throw error
    }
  }

  public func clearValues(for keys: [TDSecureStorageKey]) throws {
    for key in keys {
      do {
        try self.keychainAccess.remove(key.rawValue)
      } catch {
        throw error
      }
    }
  }
}
