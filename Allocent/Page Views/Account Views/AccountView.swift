//
//  AccountView.swift
//  BudgetApp
//
//  Created by Valerie on 2/23/26.
//

import SwiftUI
import UserNotifications

struct AccountView: View {
    @EnvironmentObject var session: SessionViewModel
    @State private var pushNotifications = false
    @State private var budgetAlerts = false
    @AppStorage("isDarkMode") private var darkMode = false
    @Environment(\.scenePhase) private var scenePhase
    
    //get the user info to display
    private var currentUser: AppUser? {
        switch session.state {
        case .active(let user), .onboarding(let user):
            return user
        default:
            return nil
        }
    }

    private var displayName: String {
        let first = currentUser?.firstName ?? ""
        let last = currentUser?.lastName ?? ""
        let full = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)
        return full.isEmpty ? "Account" : full
    }

    private var displayEmail: String {
        currentUser?.email ?? ""
    }
    
    var body: some View {
        
        ZStack {
            Color("Background").ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                Header(categoryName: "Account")
                
                //Name and email

                HStack(spacing: 16) {
                   if let urlString = currentUser?.profileImageURL,
                              let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            default:
                                Circle()
                                    .fill(Color("OliveGreen").opacity(0.3))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "person")
                                            .foregroundStyle(Color("OliveGreen"))
                                            .font(.system(size: 24, weight: .bold))
                                    )
                            }
                        }
                    } else {
                        Circle()
                            .fill(Color("OliveGreen").opacity(0.3))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person")
                                    .foregroundStyle(Color("OliveGreen"))
                                    .font(.system(size: 24, weight: .bold))
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text(displayEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                
                ScrollView {
                    //Profile
                    VStack(spacing: 0) {
                        HStack {
                            Text("Profile")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 23)
                        Divider()
                        
                        NavigationLink {
                            EditProfile()
                                .navigationBarBackButtonHidden()
                        } label: {
                            AccountRowNavigation(title: "Edit Profile", icon: "person")
                        }.buttonStyle(.plain)
                        
                        Divider()
                        NavigationLink {
                            EmailPreferencesView()
                                .navigationBarBackButtonHidden()
                        } label: {
                            AccountRowNavigation(title: "Email Preferences", icon: "envelope")
                        }.buttonStyle(.plain)
                    }
                    .background(Color("CardBackground"))
                    .cornerRadius(9)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    //Settings
                    VStack(spacing: 0) {
                        HStack {
                            Text("Settings")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 23)
                        Divider()
                        AccountRowToggle(title: "Push Notifications", icon: "bell", isOn: $pushNotifications)
                        Divider()
                        AccountRowToggle(title: "Budget Alerts", icon: "bell.badge", isOn: $budgetAlerts)
                        Divider()
                        AccountRowToggle(title: "Dark Mode", icon: "moon", isOn: $darkMode)
                        Divider()
                        NavigationLink {
                            ConnectedAccountsView()
                                .navigationBarBackButtonHidden()
                        } label: {
                            AccountRowNavigation(title: "Connected Accounts", icon: "creditcard")
                        }.buttonStyle(.plain)
                    }
                    .background(Color("CardBackground"))
                    .cornerRadius(9)
                    .padding()
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    //Support
                    VStack(spacing: 0) {
                        HStack {
                            Text("Support")
                                .font(.title3)
                                .bold()
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 23)
                        Divider()
                        AccountRowNavigation(title: "FAQ", icon: "questionmark.circle")
                        Divider()
                        AccountRowNavigation(title: "Privacy Policy", icon: "lock.shield")
                        Divider()
                        AccountRowNavigation(title: "Terms of Service", icon: "doc.text")
                    }
                    .background(Color("CardBackground"))
                    .cornerRadius(9)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
                    
                    Button {
                        session.signOut()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("CardBackground"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.red, lineWidth: 0.4)
                        )
                    }
                    .padding()
                }
                //                    .padding(.horizontal)
            }
        }
        .onChange(of: darkMode) { _, newValue in
            applyTheme(darkMode: newValue)
        }
        .onChange(of: pushNotifications) { oldValue, newValue in
            guard newValue != oldValue else { return }
            handleNotificationToggle(newValue)
        }
        .task {
            await syncNotificationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await syncNotificationStatus()
                    await session.refreshUser()}
            }
        }
    }

    private func syncNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let isAuthorized = settings.authorizationStatus == .authorized
        if pushNotifications != isAuthorized {
            pushNotifications = isAuthorized
        }
    }

    private func handleNotificationToggle(_ isOn: Bool) {
        Task {
            let center = UNUserNotificationCenter.current()
            let status = await center.notificationSettings().authorizationStatus

            if isOn {
                if status == .notDetermined {
                    let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                    if !granted {
                        pushNotifications = false
                    }
                } else if status == .denied {
                    // Permission was previously denied — open Settings
                    pushNotifications = false
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        await UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    private func applyTheme(darkMode: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.overrideUserInterfaceStyle = darkMode ? .dark : .light
    }
}

// Helper views for the Account Page rows
struct AccountRowNavigation: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.primary)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct AccountRowToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color("OliveGreen"))
        }
        .padding()
    }
}

#Preview {
    AccountView()
        .environmentObject(SessionViewModel())
}
