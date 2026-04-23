//
//  EmailService.swift
//  Allocent
//
//  Created by Valerie on 4/22/26.
//


import Foundation

final class EmailService {
    static let shared = EmailService()
    
    private init() {}

    func sendEmail(to: String, subject: String, message: String) async throws {
        print("in send email")
        guard let url = URL(string: "https://api.resend.com/emails") else { return }
        print("past guard in send email")

        let body: [String: Any] = [
            "from": "Allocent <onboarding@resend.dev>",
            "to": to,
            "subject": subject,
            "html": "<p>\(message)</p>"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.resendAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            print(String(data: data, encoding: .utf8) ?? "")
            throw URLError(.badServerResponse)
        }
    }
}
