import SwiftUI

struct ContentView: View {
    @Environment(NoteStore.self) private var store

    @State private var editing: Note?

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.notes) { note in
                    Button {
                        editing = note
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title.isEmpty ? "Untitled" : note.title)
                                .font(.headline)
                            if !note.body.isEmpty {
                                Text(note.body)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    indexSet.map { store.notes[$0] }.forEach(store.delete)
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.add()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(item: $editing) { note in
                NavigationStack {
                    NoteEditorView(note: note)
                }
            }
            .overlay {
                if store.notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes",
                        systemImage: "note.text",
                        description: Text("Tap the compose button to add one.")
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(NoteStore())
}
