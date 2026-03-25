//
//  AppUser.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation

struct AppUser: Identifiable, Codable, Equatable {
    // Firebase uid
    let id: String
    
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var bio: String

    var createdAt: Date
    var needsOnboarding: Bool

    
    // bank api integration goes here
    var linked: Bool
    // last synced?
    
    
}

