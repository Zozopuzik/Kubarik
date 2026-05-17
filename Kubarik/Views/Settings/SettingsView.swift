//
//  SettingsView.swift
//  Kubarik
//
//  Standalone preferences screen reachable from the welcome icon row.
//  Same preference store as the Profile → Preferences tab, so toggles
//  here mirror toggles there.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PreferencesStore.self) private var prefs

    var body: some View {
        ZStack(alignment: .topLeading) {
            CreamBackground()

            VStack(spacing: 0) {
                header

                Spacer().frame(height: 18)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        PrefSection(label: "Audio & feel") {
                            PrefRow(label: "Music", divider: true) {
                                ToggleSwitch(isOn: Binding(get: { prefs.music }, set: { prefs.music = $0 }))
                            }
                            PrefRow(label: "Haptics") {
                                HapticLevelPicker(value: Binding(
                                    get: { prefs.hapticLevel },
                                    set: { prefs.hapticLevel = $0 }
                                ))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .center) {
            IconButton(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
            }
            Spacer()
            Text("Settings")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.textBrown)
            Spacer()
            Color.clear.frame(width: 52, height: 52)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}
