import SwiftUI

struct ProphetListView: View {
    @StateObject private var viewModel = ProphetListViewModel()
    @State private var showingAddProphet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.prophets) { prophet in
                    NavigationLink(destination: ProphetEditView(prophet: prophet)) {
                        HStack {
                            Image(systemName: prophet.iconName ?? "person.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(prophet.name)
                                    .font(.headline)
                                Text(String(prophet.systemPrompt.prefix(50)) + "...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: viewModel.deleteProphets)
            }
            .navigationTitle("Prophets")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProphet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProphet) {
                ProphetEditView(prophet: nil)
            }
        }
    }
}