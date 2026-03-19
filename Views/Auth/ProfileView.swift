import SwiftUI
import Supabase

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var coinManager = CoinManager.shared
    @State private var showDeleteConfirmation = false
    @State private var showSignOutConfirmation = false
    
    @State private var fullName = ""
    @State private var username = ""
    @State private var isEditing = false
    @State private var isSaving = false
    
    // Toast State
    @State private var toastMessage: String? = nil
    @State private var toastIcon: String = "checkmark.circle.fill"
    @State private var toastColor: Color = .green
    @State private var showToast = false

    var body: some View {
        ZStack {
            List {
                // Profile header
                Section {
                if isEditing {
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Full Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.indigo)
                                TextField("Enter full name", text: $fullName)
                                    .textContentType(.name)
                            }
                            .padding(10)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Username")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("*")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            HStack {
                                Image(systemName: "at")
                                    .foregroundColor(.indigo)
                                TextField("Choose a username", text: $username)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                            }
                            .padding(10)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(10)
                            
                            if username.trimmingCharacters(in: .whitespaces).isEmpty {
                                Text("Username is required")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }

                        HStack(spacing: 12) {
                            Button(action: {
                                withAnimation {
                                    isEditing = false
                                    loadCurrentData()
                                }
                            }) {
                                Text("Cancel")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color(uiColor: .systemGray6))
                                    .cornerRadius(10)
                            }

                            Button(action: saveProfile) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Save")
                                            .fontWeight(.bold)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(isSaving || fullName.isEmpty || username.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.indigo)
                                .cornerRadius(10)
                            }
                            .disabled(isSaving || fullName.isEmpty || username.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(.vertical, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)

                            Text(authService.userInitial)
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(authService.userDisplayName)
                                    .font(.system(.headline, design: .rounded))

                                if StoreKitManager.shared.isPro {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }

                            if !authService.username.isEmpty {
                                Text("@\(authService.username)")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                            }

                            Text(authService.userEmail)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary.opacity(0.8))
                        }

                        Spacer()

                        Button(action: {
                            loadCurrentData()
                            withAnimation { isEditing = true }
                            HapticService.shared.impact(style: .light)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                Text("Edit")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.indigo)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            // Pro Status Section
            Section {
                HStack {
                    Label("Account Status", systemImage: StoreKitManager.shared.isPro ? "crown.fill" : "person.fill")
                    Spacer()
                    Text(StoreKitManager.shared.isPro ? "LoanPro+ Active" : "Free Tier")
                        .fontWeight(.semibold)
                        .foregroundColor(StoreKitManager.shared.isPro ? .orange : .secondary)
                }

                if !StoreKitManager.shared.isPro {
                    NavigationLink(destination: ProUpgradeView()) {
                        Text("Upgrade to Pro")
                            .foregroundColor(.indigo)
                            .fontWeight(.medium)
                    }
                } else if !authService.isAuthenticated {
                    // This case shouldn't happen inside ProfileView as it requires Auth, 
                    // but for completeness if we showed Profile for guests...
                } else {
                    Button(action: {
                        Task { await StoreKitManager.shared.syncProStatusToCloud() }
                    }) {
                        Label("Sync Subscription", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.indigo)
                    }
                }
            }            
            // Stats
            Section(header: Text(L10n.string("account_stats"))) {
                HStack {
                    Label(L10n.string("coin_balance"), systemImage: "circle.fill")
                        .foregroundColor(.orange)
                    Spacer()
                    Text("\(coinManager.coinBalance)")
                        .fontWeight(.semibold)
                        .foregroundColor(.indigo)
                }
                
                HStack {
                    Label(L10n.string("calculations_made"), systemImage: "function")
                    Spacer()
                    Text("\(SettingsManager.shared.calculationCount)")
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            
            // Account actions
            Section(header: Text(L10n.string("account"))) {
                Button(action: {
                    showSignOutConfirmation = true
                }) {
                    Label(L10n.string("sign_out"), systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.primary)
                }
                
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Label(L10n.string("delete_account"), systemImage: "trash.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.string("profile"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.string("sign_out"), isPresented: $showSignOutConfirmation) {
            Button(L10n.string("sign_out"), role: .destructive) {
                Task { await authService.signOut() }
            }
            Button(L10n.string("cancel"), role: .cancel) {}
        } message: {
            Text(L10n.string("sign_out_confirm"))
        }
        .alert(L10n.string("delete_account"), isPresented: $showDeleteConfirmation) {
            Button(L10n.string("delete_account"), role: .destructive) {
                Task { await authService.deleteAccount() }
            }
            Button(L10n.string("cancel"), role: .cancel) {}
        } message: {
            Text(L10n.string("delete_account_confirm"))
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                dismiss()
            }
        }
        .onAppear {
            loadCurrentData()
        }
        
            // Toast Overlay
            if showToast, let message = toastMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: toastIcon)
                            .foregroundColor(toastColor)
                            .font(.title3)
                        
                        Text(message)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.top, 10) // Push down from the top edge
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1) // Ensure it stays on top
            }
        } // End ZStack
    }
    
    private func showToastMessage(_ message: String, isError: Bool = false) {
        toastMessage = message
        toastIcon = isError ? "xmark.circle.fill" : "checkmark.circle.fill"
        toastColor = isError ? .red : .green
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showToast = true
        }
        
        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showToast = false
            }
        }
    }
    
    private func loadCurrentData() {
        fullName = authService.userDisplayName
        username = authService.username
    }
    
    private func saveProfile() {
        isSaving = true
        Task {
            do {
                guard let userId = authService.currentUser?.id else {
                    showToastMessage("User not logged in", isError: true)
                    isSaving = false
                    return
                }
                
                let cleanFullName = fullName.trimmingCharacters(in: .whitespaces)
                let cleanUsername = username.trimmingCharacters(in: .whitespaces)
                
                print("ProfileView: Attempting to save profile")
                print("ProfileView: - Name: '\(cleanFullName)' (length: \(cleanFullName.count))")
                print("ProfileView: - Username: '\(cleanUsername)' (length: \(cleanUsername.count))")
                print("ProfileView: - Raw username state: '\(username)' (length: \(username.count))")
                
                guard !cleanUsername.isEmpty else {
                    showToastMessage("Username is required", isError: true)
                    isSaving = false
                    return
                }
                
                // 1. Prepare Upsert Data
                // To be completely safe and not overwrite existing coins/pro status, we use the values from the current session
                let profileData: [String: AnyJSON] = [
                    "id": AnyJSON.string(userId.uuidString),
                    "full_name": AnyJSON.string(cleanFullName),
                    "username": AnyJSON.string(cleanUsername),
                    "coin_balance": AnyJSON.integer(CoinManager.shared.coinBalance),
                    "is_pro": AnyJSON.bool(StoreKitManager.shared.isPro),
                    "updated_at": AnyJSON.string(ISO8601DateFormatter().string(from: Date()))
                ]
                
                print("ProfileView: Upsert Payload -> \(profileData)")
                
                // 2. Execute Upsert
                try await SupabaseManager.client.from("profiles")
                    .upsert(profileData)
                    .execute()
                
                print("ProfileView: Database upsert successful")
                
                // 3. Update Auth metadata (for local session consistency)
                let attributes = UserAttributes(
                    data: [
                        "full_name": AnyJSON.string(cleanFullName),
                        "username": AnyJSON.string(cleanUsername)
                    ]
                )
                _ = try? await SupabaseManager.client.auth.update(user: attributes)
                
                // 4. Refresh local state
                await authService.fetchUserProfile(userId: userId)
                
                await MainActor.run {
                    withAnimation {
                        isEditing = false
                    }
                    HapticService.shared.notification(type: .success)
                    showToastMessage("Profile updated successfully")
                }
                
            } catch {
                print("ProfileView: Error saving profile completely: \(error)")
                await MainActor.run {
                    HapticService.shared.notification(type: .error)
                    showToastMessage("Failed to update: \(error.localizedDescription)", isError: true)
                }
            }
            
            await MainActor.run {
                isSaving = false
            }
        }
    }
}
