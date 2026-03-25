//
//  SessionState.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation

enum SessionState: Equatable {
    case loading
        case signedOut
        case onboarding(AppUser)
        case active(AppUser)
        case error(String)
}
