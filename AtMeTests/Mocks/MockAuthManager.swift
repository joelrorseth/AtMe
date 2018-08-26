//
//  AuthManagerMock.swift
//  AtMeTests
//
//  Created by Joel Rorseth on 2018-08-25.
//  Copyright © 2018 Joel Rorseth. All rights reserved.
//

import UIKit

class MockAuthManager: AuthManager {
  
  var authenticationDelegate: AuthenticationDelegate?
  
  func createAccount(email: String, firstName: String, lastName: String, password: String, completion: @escaping ((Error?, String?) -> ())) {
    // TODO
  }
  
  func signIn(email: String, password: String, completion: @escaping ((Error?, Bool) -> ())) {
    // TODO
  }
  
  func signOut() throws {
    // TODO
  }
}
