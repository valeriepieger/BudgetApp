//
//  SignUpForm.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import Foundation

struct SignUpForm: Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var bio: String = ""

    var password: String = ""
    var confirmPassword: String = ""
}
