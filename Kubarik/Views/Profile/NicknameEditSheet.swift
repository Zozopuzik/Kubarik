//
//  NicknameEditSheet.swift
//  Kubarik
//
//  Tiny bottom sheet for renaming the signed-in user. Same chrome as
//  EmailSignInSheet — solid cream background via `.presentationBackground`,
//  pre-filled text field, Save / Cancel buttons.
//

import SwiftUI

struct NicknameEditSheet: View {
    let currentName: String
    var onSubmit: (String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var nickname: String = ""
    @State private var isSubmitting = false
    @State private var error: String? = nil

    private let maxLength = 16
    private let minLength = 2

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 28)

            Text("EDIT NICKNAME")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(2.5)
                .foregroundStyle(Palette.taglineBrown)

            Spacer().frame(height: 10)

            Text("Other players see this on the leaderboard.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.textBrown.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer().frame(height: 26)

            nicknameField

            Spacer().frame(height: 12)

            if let error {
                Text(error)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            Spacer().frame(height: 18)

            PlayButton(
                color: .mint,
                label: isSubmitting ? "..." : "SAVE",
                width: 252,
                action: submit
            )
            .disabled(isSubmitting || !isValid)
            .opacity(isValid ? 1 : 0.55)

            Spacer().frame(height: 12)

            Button(action: { dismiss() }) {
                Text("CANCEL")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Palette.textBrown.opacity(0.65))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .presentationDetents([.fraction(0.55)])
        .presentationCornerRadius(34)
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0xFFF3DF))
        .onAppear {
            nickname = currentName
        }
    }

    private var nicknameField: some View {
        TextField("Your name", text: $nickname)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.textBrown)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit(submit)
            .onChange(of: nickname) { _, new in
                if new.count > maxLength {
                    nickname = String(new.prefix(maxLength))
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .frame(width: 280)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Palette.textBrown.opacity(0.25), lineWidth: 1.5)
                    )
            )
    }

    private var isValid: Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minLength && trimmed != currentName
    }

    private func submit() {
        guard isValid, !isSubmitting else { return }
        let value = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                try await onSubmit(value)
                dismiss()
            } catch {
                self.error = "Couldn't save. Try again."
            }
        }
    }
}
