import SwiftUI
import MyGolfGPSCore

struct ContentView: View {
    @EnvironmentObject var session: PhoneSession
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                if let course = session.selectedCourse {
                    Section("Selected Course") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(course.name).font(.headline)
                            Text("\(course.mappedHoleCount)/\(course.totalHoles) holes mapped")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button("Start on Watch") {
                                session.startRoundOnWatch()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Search") {
                    HStack {
                        TextField("Course name", text: $query)
                            .textInputAutocapitalization(.words)
                        Button("Go") {
                            Task { await session.search(query: query) }
                        }
                        .disabled(session.isSearching || session.location == nil)
                    }

                    if session.isSearching {
                        ProgressView("Searching OSM…")
                    }

                    ForEach(session.searchResults) { result in
                        Button {
                            Task { await session.download(result) }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(result.name)
                                if let meters = result.distanceMeters {
                                    Text(String(format: "%.1f mi away", meters / 1609.34))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(session.isDownloading)
                    }
                }

                if let error = session.errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("MyGolfGPS")
            .onAppear { session.requestLocation() }
            .overlay {
                if session.isDownloading {
                    ProgressView("Downloading course…")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
