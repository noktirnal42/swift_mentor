import SwiftUI

struct SnippetLibraryView: View {
    @StateObject private var viewModel = SnippetLibraryViewModel()
    @State private var searchText = ""

    var body: some View {
        HSplitView {
            categorySidebar
                .frame(minWidth: 200, maxWidth: 250)

            snippetList
        }
        .navigationTitle("Snippet Library")
        .task {
            await viewModel.loadSnippets()
        }
    }

    private var categorySidebar: some View {
        List(selection: Binding(
            get: { viewModel.selectedCategory ?? "" },
            set: { viewModel.selectCategory($0.isEmpty ? nil : $0) }
        )) {
            Section("All Snippets") {
                Button(action: { viewModel.selectCategory(nil) }) {
                    Label("All", systemImage: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundColor(viewModel.selectedCategory == nil ? .accentColor : .primary)
            }

            Section("Categories") {
                ForEach(viewModel.categories, id: \.self) { category in
                    Label {
                        Text(category)
                    } icon: {
                        Image(systemName: "folder")
                    }
                    .tag(category)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var snippetList: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search snippets...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            List(viewModel.filteredSnippets) { snippet in
                SnippetRow(snippet: snippet)
            }
            .listStyle(.inset)
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchSnippets(newValue)
        }
    }
}

struct SnippetRow: View {
    let snippet: CodeSnippet
    @State private var showCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snippet.title)
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text(snippet.shortcut)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        Text(snippet.topic.replacingOccurrences(of: "-", with: " ").capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: copyToClipboard) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundColor(showCopied ? .green : .secondary)
            }

            Text(snippet.description)
                .font(.caption)
                .foregroundColor(.secondary)

            CodeBlockView(code: snippet.displayCode, language: "swift")
                .frame(maxHeight: 100)
        }
        .padding(.vertical, 8)
        .contextMenu {
            Button("Copy to Clipboard") { copyToClipboard() }
            Button("Use in Playground") {
                AppState.shared.selectedSection = .playground
            }
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.code, forType: .string)
        showCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopied = false
        }
    }
}

#Preview {
    SnippetLibraryView()
}