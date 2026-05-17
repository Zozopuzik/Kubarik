//
//  EmailSignInSheet.swift
//  Kubarik
//
//  Email + password sign-in / sign-up. Replaced the magic-link flow
//  because Supabase rate-limits magic-link emails (~4/hour) and the
//  deep-link round-trip is fragile for new users.
//
//  Three phases:
//  - `.input`   : email field, password field, mode toggle
//  - `.success` : check-mark celebration, auto-dismiss
//
//  Requires Supabase "Confirm email" to be OFF — otherwise sign-up
//  returns no session and we surface the error.
//

import SwiftUI

struct EmailSignInSheet: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var mode: Mode = .signIn
    @State private var phase: Phase = .input
    @State private var error: String? = nil
    @State private var isSubmitting = false

    enum Phase { case input, success }
    enum Mode { case signIn, signUp

        var ctaLabel: String {
            switch self {
            case .signIn: return "SIGN IN"
            case .signUp: return "JOIN US"
            }
        }

        var title: String {
            switch self {
            case .signIn: return "SIGN IN"
            case .signUp: return "JOIN US"
            }
        }

        var switchPrompt: String {
            switch self {
            case .signIn: return "New here? Join us"
            case .signUp: return "Have an account? Sign in"
            }
        }

        var toggled: Mode { self == .signIn ? .signUp : .signIn }
    }

    var body: some View {
        ZStack {
            inputPhase
                .opacity(phase == .input ? 1 : 0)
                .allowsHitTesting(phase == .input)

            successPhase
                .opacity(phase == .success ? 1 : 0)
                .allowsHitTesting(phase == .success)
        }
        .animation(.easeInOut(duration: 0.28), value: phase)
        .presentationDetents([.fraction(0.58)])
        .presentationCornerRadius(34)
        .presentationDragIndicator(phase == .success ? .hidden : .visible)
        .interactiveDismissDisabled(phase == .success)
        .presentationBackground(Color(hex: 0xFFF3DF))
        .onChange(of: auth.state) { _, newState in
            if case .signedIn = newState, phase != .success {
                phase = .success
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(1800))
                    dismiss()
                }
            }
        }
    }

    // MARK: - Input phase

    private var inputPhase: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            Text(mode.title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .tracking(2.8)
                .foregroundStyle(Palette.taglineBrown)

            Spacer().frame(height: 24)

            VStack(spacing: 12) {
                emailField
                passwordField
            }

            if let error {
                Text(error)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)
            }

            Spacer().frame(height: 22)

            PlayButton(
                color: .mint,
                label: isSubmitting ? "..." : mode.ctaLabel,
                width: 290,
                action: submit
            )
            .disabled(isSubmitting || !isValid)
            .opacity(isValid ? 1 : 0.55)

            Spacer().frame(height: 18)

            Button(action: toggleMode) {
                Text(mode.switchPrompt)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Palette.textBrown.opacity(0.6))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emailField: some View {
        labeledField(
            icon: "envelope.fill",
            placeholder: "Your email",
            text: $email,
            isSecure: false
        )
        .keyboardType(.emailAddress)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(.next)
    }

    private var passwordField: some View {
        labeledField(
            icon: "lock.fill",
            placeholder: "Your password",
            text: $password,
            isSecure: true
        )
        .textContentType(mode == .signUp ? .newPassword : .password)
        .submitLabel(.go)
        .onSubmit(submit)
    }

    /// Field row with an icon, custom-color placeholder, and our cream
    /// inset background. iOS doesn't expose a placeholder-color modifier
    /// directly so we render the placeholder ourselves as a ZStack overlay
    /// and feed an empty prompt into the TextField.
    private func labeledField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.taglineBrown.opacity(0.55))
                .frame(width: 18)

            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(Palette.textBrown.opacity(0.38))
                }
                Group {
                    if isSecure {
                        SecureField("", text: text)
                    } else {
                        TextField("", text: text)
                    }
                }
                .foregroundStyle(Palette.textBrown)
                .tint(Palette.textBrown)
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .frame(width: 290)
        .background(fieldBackground)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Palette.textBrown.opacity(0.18), lineWidth: 1.2)
            )
            .shadow(color: Palette.textBrown.opacity(0.08), radius: 6, y: 3)
    }

    private var isValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".") && password.count >= 6
    }

    private func toggleMode() {
        withAnimation(.easeInOut(duration: 0.18)) {
            mode = mode.toggled
            error = nil
        }
    }

    private func submit() {
        guard isValid, !isSubmitting else { return }
        error = nil
        let cleanEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        let pw = password
        let currentMode = mode

        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                switch currentMode {
                case .signIn:
                    try await auth.signIn(email: cleanEmail, password: pw)
                case .signUp:
                    try await auth.signUp(email: cleanEmail, password: pw)
                }
            } catch {
                self.error = humanError(error, mode: currentMode)
            }
        }
    }

    private func humanError(_ error: Error, mode: Mode) -> String {
        let raw = "\(error)".lowercased()
        if raw.contains("invalid login") || raw.contains("invalid_credentials") {
            return "Wrong email or password."
        }
        if raw.contains("user already registered") || raw.contains("already exists") {
            return "Account exists — try Sign in instead."
        }
        if raw.contains("confirm email") {
            return "Email confirmation is required.\nTurn off 'Confirm email' in Supabase."
        }
        if raw.contains("password") && raw.contains("6") {
            return "Password must be at least 6 characters."
        }
        return mode == .signIn ? "Couldn't sign in. Try again." : "Couldn't create account. Try again."
    }
}

// MARK: - Success phase

private struct SuccessContent: View {
    let profileName: String?

    @State private var animated = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 36)

            ZStack {
                Circle()
                    .fill(TileColor.mint.top)
                    .frame(width: 92, height: 92)
                    .shadow(color: TileColor.mint.edge, radius: 0, x: 0, y: 8)
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 10)

                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(.white)
                    .shadow(color: TileColor.mint.edge.opacity(0.5), radius: 0, x: 0, y: 2)
            }
            .scaleEffect(animated ? 1.0 : 0.4)
            .opacity(animated ? 1.0 : 0)

            Spacer().frame(height: 22)

            Text("YOU'RE IN!")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .tracking(2.5)
                .foregroundStyle(Palette.textBrown)
                .opacity(animated ? 1 : 0)
                .offset(y: animated ? 0 : 10)

            Spacer().frame(height: 8)

            if let profileName {
                Text("Welcome, \(profileName)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.textBrown.opacity(0.7))
                    .opacity(animated ? 1 : 0)
                    .offset(y: animated ? 0 : 10)
            }

            Spacer().frame(height: 14)

            Text("Your scores will sync across devices.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.textBrown.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .opacity(animated ? 1 : 0)
                .offset(y: animated ? 0 : 10)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.55)) {
                animated = true
            }
        }
    }
}

extension EmailSignInSheet {
    fileprivate var successPhase: some View {
        SuccessContent(profileName: auth.state.profile?.displayName)
    }
}
