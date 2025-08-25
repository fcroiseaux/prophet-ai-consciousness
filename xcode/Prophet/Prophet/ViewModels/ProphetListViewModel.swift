import Foundation
import SwiftUI
import Combine

@MainActor
class ProphetListViewModel: ObservableObject {
    @Published var prophets: [Prophet] = []
    
    private let prophetStore = ProphetStore.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to changes in the shared store
        prophetStore.$prophets
            .assign(to: &$prophets)
    }
    
    func deleteProphets(at offsets: IndexSet) {
        prophetStore.deleteProphets(at: offsets)
    }
}