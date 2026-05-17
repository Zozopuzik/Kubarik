//
//  CreamBackground.swift
//  Kubarik
//

import SwiftUI

struct CreamBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Palette.creamTop, Palette.creamBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    CreamBackground()
}
