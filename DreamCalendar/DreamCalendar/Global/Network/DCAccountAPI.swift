//
//  DCRequest.swift
//  DreamCalendar
//
//  Created by 이지수 on 2023/02/02.
//

import Foundation

protocol APIInfo {
    var route: String { get }
    var method: HttpMethod { get }
    var header: [(key: String, value: String)]? { get }
    func body() throws -> Data?
    
    var responseType: Decodable.Type? { get }
    func response(_ data: Data) throws -> Decodable?
}

fileprivate struct MessageResponse: Decodable {
    let message: String
}

extension APIInfo {
    func message(data: Data) -> String? {
        return try? JSONDecoder().decode(MessageResponse.self, from: data).message
    }
}

enum HttpMethod {
    case post, get, delete, put
    
    func toString() -> String {
        switch self {
        case .post : return "POST"
        case .get : return "GET"
        case .delete : return "DELETE"
        case .put : return "PUT"
        }
    }
}

final class DCAPI {
    
    struct TokenResponse: Decodable {
        let access_token: String
        let refresh_token: String
    }
    
    enum Account: APIInfo {
        case signup(email: String, password: String, name: String)
        case login(email: String, password: String)
        case tokenLogin(authorization: String)
        case refreshToken(refreshToken: String)
        case logout(authorization: String)
        case leave(authorization: String)
        
        var route: String {
            switch self {
            case .signup, .leave: return "/user"
            case .login, .tokenLogin : return "/auth"
            case .refreshToken : return "/auth-refresh"
            case .logout : return "/auth/logout"
            }
        }
        
        var method: HttpMethod {
            switch self {
            case .signup, .login : return .post
            case .tokenLogin, .refreshToken, .logout : return .get
            case .leave : return .delete
            }
        }

        var header: [(key: String, value: String)]? {
            switch self {
            case .signup, .login :
                return [("Content-Type", "application/json")]
            case .tokenLogin(let authorization), .logout(let authorization), .leave(let authorization), .refreshToken(let authorization) :
                return [("Authorization", authorization)]
            }
        }
        
        func body() throws -> Data? {
            let body: [String: Any]
            switch self {
            case .signup(let email, let password, let username) :
                body = ["email": email, "password": password, "name": username]
            case .login(let email, let password) :
                body = ["email": email, "password": password]
            default :
                return nil
            }
            do {
                return try JSONSerialization.data(withJSONObject: body)
            } catch {
                throw DCError.requestError(error)
            }
        }
        
        var responseType: Decodable.Type? {
            switch self {
            case .login, .refreshToken :
                return TokenResponse.self
            default :
                return nil
            }
        }
        
        func response(_ data: Data) throws -> Decodable? {
            guard let responseType = self.responseType else { return nil }
            do {
                return try JSONDecoder().decode(responseType, from: data)
            } catch {
                throw DCError.decodingError(data)
            }
        }
    }
}

