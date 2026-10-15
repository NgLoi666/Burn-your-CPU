import Foundation
import Observation

/// Tiny JSON-backed store. Uses the Observation framework (`@Observable`)
/// so SwiftUI views update automatically without `ObservableObject`/`@Published`.
@Observable
final class NoteStore {
    private(set) var notes: [Note] = []

    private let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        fileURL = base.appendingPathComponent("notes.json")
        load()
    }

    func add() {
        notes.insert(Note(), at: 0)
        save()
    }

    func update(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index] = note
        save()
    }

    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        notes = (try? JSONDecoder().decode([Note].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
