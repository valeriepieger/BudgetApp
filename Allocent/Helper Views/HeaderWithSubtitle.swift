//
//  HeaderWithSubtitle.swift
//  Allocent
//
//  Created by Amber Liu on 2/26/26.
//

import SwiftUI

struct HeaderWithSubtitle: View {
    var title: String
        var subtitle: String

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color.black.opacity(0.55))
            }
//            .padding(.horizontal)
            .padding(.top, 10)
        }
}

#Preview {
    HeaderWithSubtitle(title: "Sign In", subtitle: "Welcome back")
}
