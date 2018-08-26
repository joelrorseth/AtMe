//
//  AuthManager.swift
//  AtMe
//
//  Created by Joel Rorseth on 2018-08-25.
//  Copyright © 2018 Joel Rorseth. All rights reserved.
//

protocol AuthManager {
  
  var authenticationDelegate: AuthenticationDelegate? { get set }
  
  func createAccount(email: String, firstName: String, lastName: String, password: String,
                     completion: @escaping ((Error?, String?) -> ()))
  
  func signIn(email: String, password: String, completion: @escaping ((Error?, Bool) -> ()))
  
  func signOut() throws
}
