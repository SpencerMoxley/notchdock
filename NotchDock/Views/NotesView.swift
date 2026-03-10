import SwiftUI

struct NotesView: View {
    @State private var text = ""

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.75))
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            if text.isEmpty {
                Text("Scratch pad…")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
        }
    }
}
