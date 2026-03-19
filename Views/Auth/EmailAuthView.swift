import SwiftUI

struct EmailAuthView: View {
    @ObservedObject var authService = AuthService.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var username = ""
    @State private var isSignUp: Bool
    @State private var showResetPassword = false
    @State private var resetEmail = ""
    @State private var showResetConfirmation = false
    @State private var showSuccessAnimation = false
    
    init(isSignUp: Bool = false) {
        _isSignUp = State(initialValue: isSignUp)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: isSignUp ? "person.badge.plus.fill" : "person.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.indigo)
                    
                    Text(isSignUp ? L10n.string("create_account") : L10n.string("welcome_back"))
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text(isSignUp ? L10n.string("create_account_subtitle") : L10n.string("sign_in_subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Input fields
                VStack(spacing: 16) {
                    // Name & Username (sign-up only)
                    if isSignUp {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.indigo)
                                .frame(width: 24)
                            TextField("Full Name", text: $fullName)
                                .textContentType(.name)
                                .autocapitalization(.words)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        
                        HStack {
                            Image(systemName: "at")
                                .foregroundColor(.indigo)
                                .frame(width: 24)
                            TextField("Username", text: $username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(14)
                    }
                    
                    // Email
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        TextField(L10n.string("email_placeholder"), text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(14)
                    
                    // Password
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        SecureField(L10n.string("password_placeholder"), text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(14)
                }
                .padding(.horizontal)
                
                // Error message
                if let error = authService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Submit button
                Button(action: submitForm) {
                    submitButtonLabel
                }
                .disabled(!isFormValid || authService.isLoading)
                .padding(.horizontal)
                
                // Toggle sign-in / sign-up
                VStack(spacing: 12) {
                    Button(action: {
                        withAnimation { isSignUp.toggle() }
                        authService.errorMessage = nil
                    }) {
                        Text(isSignUp ? L10n.string("already_have_account") : L10n.string("dont_have_account"))
                            .font(.subheadline)
                            .foregroundColor(.indigo)
                    }
                    
                    if !isSignUp {
                        Button(action: { showResetPassword = true }) {
                            Text(L10n.string("forgot_password"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
        .navigationTitle(isSignUp ? L10n.string("sign_up") : L10n.string("sign_in"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(L10n.string("cancel")) { dismiss() }
            }
        }
        .alert(L10n.string("reset_password"), isPresented: $showResetPassword) {
            TextField(L10n.string("email_placeholder"), text: $resetEmail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            Button(L10n.string("send_reset_link")) {
                Task { await authService.resetPassword(email: resetEmail) }
                showResetConfirmation = true
            }
            Button(L10n.string("cancel"), role: .cancel) {}
        }
        .alert(L10n.string("check_email"), isPresented: $showResetConfirmation) {
            Button("OK") {}
        } message: {
            Text(L10n.string("reset_link_sent"))
        }
        .onChange(of: authService.isAuthenticated) { _, authenticated in
            if authenticated {
                withAnimation { showSuccessAnimation = true }
                // Delay dismissal slightly to show the checkmark
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var submitButtonLabel: some View {
        HStack {
            if authService.isLoading {
                ProgressView()
                    .tint(.white)
            } else if showSuccessAnimation {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                Text(L10n.string("success"))
                    .fontWeight(.bold)
            } else {
                Text(isSignUp ? L10n.string("sign_up") : L10n.string("sign_in"))
                    .fontWeight(.bold)
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(submitButtonColor)
        .cornerRadius(14)
    }
    
    private var submitButtonColor: Color {
        if !isFormValid { return .gray }
        if showSuccessAnimation { return .green }
        return .indigo
    }
    
    private var isFormValid: Bool {
        let baseValid = !email.isEmpty && email.contains("@") && password.count >= 6
        if isSignUp {
            return baseValid && !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return baseValid
    }
    
    private func submitForm() {
        guard isFormValid else { return }
        
        // Front-end validation for weak passwords during sign-up
        if isSignUp && password.count < 6 {
            authService.errorMessage = L10n.string("error_weak_password")
            HapticService.shared.notification(type: .warning)
            return
        }
        
        Task {
            if isSignUp {
                await authService.signUp(
                    email: email,
                    password: password,
                    fullName: fullName.trimmingCharacters(in: .whitespaces),
                    username: username.trimmingCharacters(in: .whitespaces)
                )
            } else {
                await authService.signIn(email: email, password: password)
            }
            
            if authService.isAuthenticated {
                HapticService.shared.notification(type: .success)
            }
        }
    }
}
