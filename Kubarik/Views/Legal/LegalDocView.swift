//
//  LegalDocView.swift
//  Kubarik
//
//  Scrollable sheet that renders either the Terms of Use or Privacy
//  Policy body text from `LegalDoc`. Bullet-style paragraphs are kept
//  intact via fixed-width spacing — no markdown parsing.
//

import SwiftUI

struct LegalDocView: View {
    let doc: LegalDoc
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(doc.lastUpdated)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(Palette.taglineBrown.opacity(0.7))

                    Text(doc.body)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Palette.textBrown)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(CreamBackground().ignoresSafeArea())
            .navigationTitle(doc.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.textBrown)
                }
            }
        }
        .presentationBackground(Color(hex: 0xFFF3DF))
    }
}

#Preview {
    LegalDocView(doc: .privacy)
}
