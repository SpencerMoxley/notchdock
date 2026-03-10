import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FileTrayView: View {
    @State private var model = FileTrayModel()
    @State private var isTargeted = false

    private let columns = [
        GridItem(.adaptive(minimum: 64, maximum: 80), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("File Tray")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: 0xa8dadc))
                Spacer()
                if !model.files.isEmpty {
                    Button("Clear") { model.clear() }
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0xe94560))
                        .buttonStyle(.plain)
                }
            }

            // Drop zone / grid
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(hex: 0x16213e))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isTargeted ? Color(hex: 0xe94560) : Color(hex: 0x0f3460),
                                style: StrokeStyle(lineWidth: 1.5, dash: isTargeted ? [] : [4, 4])
                            )
                    )

                if model.files.isEmpty {
                    emptyState
                } else {
                    fileGrid
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 24))
                .foregroundColor(Color(hex: 0xa8dadc).opacity(0.35))
            Text("Drop files here")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0xa8dadc).opacity(0.4))
        }
    }

    private var fileGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(model.files, id: \.self) { url in
                    FileIconCell(url: url)
                        .onDrag {
                            NSItemProvider(object: url as NSURL)
                        }
                        .contextMenu {
                            Button("Remove from Tray") {
                                model.remove(url)
                            }
                            Button("Reveal in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                }
            }
            .padding(10)
        }
    }

    // MARK: - Drop handling

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var added = false
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let u = item as? URL {
                    url = u
                } else {
                    url = nil
                }
                if let url {
                    DispatchQueue.main.async {
                        model.add(url)
                    }
                    added = true
                }
            }
        }
        return added
    }
}

// MARK: - File Icon Cell

private struct FileIconCell: View {
    let url: URL
    @State private var icon: NSImage?

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "doc")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: 0xa8dadc).opacity(0.5))
                }
            }
            .frame(width: 44, height: 44)

            Text(url.lastPathComponent)
                .font(.system(size: 9))
                .foregroundColor(Color(hex: 0xa8dadc).opacity(0.7))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
        .padding(6)
        .background(Color(hex: 0x0f3460).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onAppear {
            icon = NSWorkspace.shared.icon(forFile: url.path)
        }
    }
}
