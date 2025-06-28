
import SwiftUI

struct PsycheSpaceView: View {
    @State private var threads: [NarrativeThread] = []
    @State private var isLoading = false
    @State private var error: Error? = nil

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text(error.localizedDescription)
                } else if threads.isEmpty {
                    Text("No narrative threads found.")
                } else {
                    List(threads) { thread in
                        NavigationLink(destination: ThreadTimelineView(threadId: thread.id)) {
                            VStack(alignment: .leading) {
                                Text(thread.title)
                                    .font(.headline)
                                    .foregroundColor(.primaryText)
                                Text("\(thread.moment_count) moments")
                                    .font(.subheadline)
                                    .foregroundColor(.secondaryText)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Narrative Atlas")
            .onAppear(perform: fetchNarrativeThreads)
        }
        .background(Color.primaryBackground)
    }

    func fetchNarrativeThreads() {
        self.isLoading = true
        // In a real app, you would make a network request to fetch threads
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isLoading = false
            self.threads = [
                NarrativeThread(id: "pattern_1", title: "Morning Creativity", moment_count: 5, last_updated: Date()),
                NarrativeThread(id: "pattern_2", title: "Social Media Anxiety", moment_count: 8, last_updated: Date())
            ]
        }
    }
}

struct NarrativeThread: Identifiable, Codable {
    let id: String
    let title: String
    let moment_count: Int
    let last_updated: Date
}
