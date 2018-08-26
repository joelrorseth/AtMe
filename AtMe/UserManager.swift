//
//  UserManager.swift
//  AtMe
//
//  Created by Joel Rorseth on 2018-08-25.
//  Copyright © 2018 Joel Rorseth. All rights reserved.
//

protocol UserManager {
  
  // MARK: - Blocking users
  
  /**
   Add a given user to the current user's blocked usernames list.
   - parameters:
   - uid: The uid of the user whom the current user is blocking.
   - username: The username of the user whom the current user is blocking.
   */
  func blockUser(uid: String, username: String)
  
  /**
   Remove a given user from the current user's blocked usernames list.
   - parameters:
   - uid: The uid of the user whom the current user is unblocking.
   - username: The username of the user whom the current user is unblocking.
   */
  func unblockUser(uid: String, username: String)
  
  /**
   Find all users whom the current user has blocked.
   - parameters:
   - completion: A callback function *invoked once for every UserProfile found*.
   - profile: The UserProfile object returned for a single given user.
   */
  func findCurrentUserBlockedUsers(completion: @escaping (UserProfile) -> Void)

  /**
   Determine if current user has blocked a given user, or vice versa.
   - parameters:
   - uid: The uid of the other user whom we are checking for blocked status.
   - username: The username of the other user whom we are checking for blocked status.
   - completion: A completion callback called when a conclusion has been reached.
   - blocked: A variable passed through callback, which will be true if either user has blocked the other.
   */
  func userOrCurrentUserHasBlocked(uid: String, username: String, completion: @escaping (Bool) -> ())

  func reportUser(uid: String, username: String, violation: String, convoID: String)
  
  // MARK: - User lookup
  
  /**
   Finds details for specified users, then returns a UserProfile for each found via a completion callback.
   - parameters:
   - results: A dictionary containing (username: uid) pairs for users
   - completion: A completion callback invoked each time details are found for a user
   - profile: The UserProfile object representing and holding the details found for a specific user
   */
  func findDetailsForUsers(results: [String : String], completion: @escaping (UserProfile) -> Void)
  
  /**
   Performs a search using given string, and attempts to find a predefined number of users whom the user is most
   likely searching for. Please note that the search omits the current user.
   - parameters:
   - term: The term to search for and match usernames with
   - completion: A completion callback that fires when it has found all the results it can
   - results: An dictionary of (username, uid) pairs found in the search. Please note this may be empty if no results found!
   */
  func searchForUsers(term: String, completion: @escaping ([String : String]) -> ())
  
  /**
   Asynchronously determines if a given username has been taken in the current database
   - parameters:
   - username: Username to search for
   - completion: Callback that fires when function has finished
   - found: True if username was found in database, false otherwise
   */
  func usernameExists(username: String, completion: @escaping (Bool) -> ())
  
  /** Asynchronously determine name of user with a given uid.
   - parameters:
   - uid: The uid of the user being searched for
   - completion: Completion handler called when search has finished
   - name: The name of user found, but nil if not found
   */
  func findNameFor(uid: String, completion: @escaping (String?) -> Void)
  
  // MARK: - Current user maintenance
  /**
   Retrieve details for current user from the database. User must be authorized already.
   - parameters:
   - user: The current user, which should be authorized at this point
   - completion:Callback that fires when function has finished
   - configured: A boolean representing if the current user object could be configured (required)
   */
  func establishCurrentUser(user: User, completion: @escaping (Bool) -> ())
  
  
  /**
   Writes current user's username into their information record and usernames registry in the database. This should
   never change after set, so only call when creating account.
   - parameters:
   - username: Username chosen by the current user
   - completion: Callback that is called upon successful completion
   */
  func setUsername(username: String, completion: (() -> ()))

  /**
   Writes the database storage path of an uploaded display picture to the current user's information record
   - parameters:
   - path: The path where the display picture has been successfully uploaded to
   */
  func setDisplayPicture(path: String)
  
  
  /** Attempt to change the current user's email, if possible. This will update Auth, the database and UserState.currentUser
   - parameters:
   - email: The email to change to
   - completion: A callback function that fires when email has been set, or discovers it cannot be done
   - error: An optional error that will be set only if an error occured and email was not changed
   */
  func changeEmailAddress(to email: String, completion: @escaping (Error?) -> Void)
  
  /** Attempt to change the current user's password, but will never store or record it directly
   - parameters:
   - password: The new password requested
   - callback: Callback function that is called when Auth confirms it can or cannot perform change
   - error: An optional Error object that will hold information if and when request fails
   */
  func changePassword(password: String, callback: @escaping (Error?) -> Void)
  
  /** If possible, will set the attribute specified of the current user to the value provided.
   - parameters:
   - attribute: Attribute to change
   - value: Value to set the attribute equal to
   */
  func changeCurrentUser(attribute: String, value: String)
}
