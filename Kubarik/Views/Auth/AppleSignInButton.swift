//
//  AppleSignInButton.swift
//  Kubarik
//
//  Thin wrapper over Apple's native SignInWithAppleButton. Generates a
//  fresh nonce per tap, hands the resulting identity token + nonce to
//  AuthManager, and handles errors via a callback.
//
//  Native button styling is mandatory — Apple's review guidelines reject
//  custom-looking "Sign in with Apple" affordances.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct AppleSignInButton: View {
    var label: SignInWithAppleButton.Label = .signIn
    var onSuccess: (_ idToken: String, _ nonce: String, _ suggestedName: String?) -> Void
    var onFailure: (Error) -> Void = { _ in }

    @State private var currentNonce: String? = nil

    var body: some View {
        SignInWithAppleButton(
            label,
            onRequest: { request in
                let nonce = Self.randomNonce()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = Self.sha256(nonce)
            },
            onCompletion: { result in
                handle(result: result)
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }

    private func handle(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                onFailure(SignInError.missingToken)
                return
            }
            let suggested = credential.fullName.flatMap { formatted($0) }
            onSuccess(idToken, nonce, suggested)
        case .failure(let error):
            onFailure(error)
        }
    }

    private func formatted(_ name: PersonNameComponents) -> String? {
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let s = formatter.string(from: name).trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? nil : s
    }

    // MARK: - Nonce helpers
    // Apple requires a random nonce per request: app sends the SHA-256
    // hash, Apple round-trips the original through the identity token so
    // Supabase can verify the link.

    private static func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            guard status == errSecSuccess else { fatalError("Unable to generate nonce: \(status)") }
            for byte in bytes where remaining > 0 {
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    enum SignInError: Error {
        case missingToken
    }
}
