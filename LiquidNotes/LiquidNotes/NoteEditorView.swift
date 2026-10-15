import SwiftUI

struct NoteEditorView: View {
    @Environment(NoteStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: Note

    init(note: Note) {
        _draft = State(initialValue: note)
    }

    var body: some View {
        Form {
            TextField("Title", text: $draft.title)

            Section {
                TextEditor(text: $draft.body)
                    .frame(minHeight: 200)
            } header: {
                Text("Body")
            }
        }
        .navigationTitle("Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    store.update(draft)
                    dismiss()
                }
            }
        }
    }
}
