import SwiftUI
import AuthenticationServices
import GoogleSignIn
import CryptoKit

struct SignInView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var showEmailAuth = false
    @State private var isSignUpMode = false
    @State private var currentNonce: String?
    
    // Google Client ID
    private let googleClientID = "266908025482-e7d35lumi5mtn8su9laldcrnimlpsjdj.apps.googleusercontent.com"

    // Cryptography helper for Google and Apple nonces
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.indigo.opacity(0.15), Color(uiColor: .systemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // App branding
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.indigo.opacity(0.12))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(.indigo)
                    }
                    
                    Text("LoanPro 2025")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.black)
                    
                    Text(isSignUpMode ? L10n.string("create_account_subtitle") : L10n.string("sign_in_subtitle"))
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Picker("", selection: $isSignUpMode) {
                        Text(L10n.string("sign_in")).tag(false)
                        Text(L10n.string("sign_up")).tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 40)
                    .onChange(of: isSignUpMode) { _, _ in
                        HapticService.shared.impact(style: .light)
                    }
                }
                
                Spacer()
                
                // Sign-in buttons
                VStack(spacing: 14) {
                    // Sign in with Apple
                    SignInWithAppleButton(isSignUpMode ? .signUp : .signIn) { request in
                        HapticService.shared.impact(style: .medium)
                        let rawNonce = randomNonceString()
                        currentNonce = rawNonce
                        
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(rawNonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                               let nonce = currentNonce,
                               let appleIDToken = appleIDCredential.identityToken,
                               let idTokenString = String(data: appleIDToken, encoding: .utf8) {
                                
                                // Extract name if provided (usually only on first sign-up)
                                var fullName: String? = nil
                                if let name = appleIDCredential.fullName {
                                    let formatter = PersonNameComponentsFormatter()
                                    fullName = formatter.string(from: name)
                                }
                                
                                Task {
                                    await authService.signInWithApple(idToken: idTokenString, nonce: nonce, fullName: fullName)
                                    if authService.isAuthenticated {
                                        HapticService.shared.notification(type: .success)
                                    }
                                }
                            }
                        case .failure(let error):
                            print("Apple Sign-In failed: \(error.localizedDescription)")
                            authService.errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .cornerRadius(14)
                    
                    // Sign in with Google
                    Button(action: {
                        HapticService.shared.impact(style: .medium)
                        
                        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
                        
                        let rawNonce = randomNonceString()
                        let hashedNonce = sha256(rawNonce)
                        
                        let config = GIDConfiguration(clientID: googleClientID)
                        GIDSignIn.sharedInstance.configuration = config
                        
                        GIDSignIn.sharedInstance.signIn(
                            withPresenting: presentingViewController,
                            hint: nil,
                            additionalScopes: nil,
                            nonce: hashedNonce,
                            completion: { signInResult, error in
                                guard error == nil else {
                                    print("Google Sign-In error: \(String(describing: error))")
                                    return
                                }
                                guard let user = signInResult?.user,
                                      let idToken = user.idToken?.tokenString else { return }
                                let accessToken = user.accessToken.tokenString
                                let fullName = user.profile?.name
                                
                                Task {
                                    await authService.signInWithGoogle(idToken: idToken, accessToken: accessToken, fullName: fullName, nonce: rawNonce)
                                    if authService.isAuthenticated {
                                        HapticService.shared.notification(type: .success)
                                    }
                                }
                            }
                        )
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)
                            Text(isSignUpMode ? L10n.string("sign_up_google") : L10n.string("sign_in_google"))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Sign in with Email
                    Button(action: {
                        showEmailAuth = true
                        HapticService.shared.impact(style: .medium)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.title3)
                            Text(isSignUpMode ? L10n.string("sign_up_email") : L10n.string("sign_in_email"))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.indigo)
                        .cornerRadius(14)
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Direct Toggle Link
                    Button(action: {
                        withAnimation {
                            isSignUpMode.toggle()
                        }
                        HapticService.shared.impact(style: .medium)
                    }) {
                        HStack {
                            Text(isSignUpMode ? L10n.string("already_have_account_short") : L10n.string("dont_have_account_short"))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 32)
                
                // Error message
                if let error = authService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }
                
                // Continue as guest
                Button(action: {
                    SettingsManager.shared.hasSeenFeatureTour = true
                    dismiss()
                }) {
                    Text(L10n.string("continue_as_guest"))
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            
            // Loading overlay
            if authService.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            NavigationStack {
                EmailAuthView(isSignUp: isSignUpMode)
            }
        }
        .onChange(of: authService.isAuthenticated) { _, authenticated in
            if authenticated {
                SettingsManager.shared.hasSeenFeatureTour = true
                dismiss()
            }
        }
    }
}
