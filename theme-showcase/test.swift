import SwiftUI
import Combine
import Foundation

// MARK: - Protocols and Extensions
protocol NetworkService {
    func fetchData<T: Codable>(_ type: T.Type, from url: URL) async throws -> T
}

extension Array where Element: Identifiable {
    func uniqued() -> [Element] {
        var seen = Set<Element.ID>()
        return filter { seen.insert($0.id).inserted }
    }
}

extension String {
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return self.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    var initials: String {
        let components = self.split(separator: " ")
        let initials = components.compactMap { $0.first }
        return String(initials.prefix(2)).uppercased()
    }
}

extension Color {
    static let primaryAccent = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let secondaryAccent = Color(red: 0.9, green: 0.4, blue: 0.2)
    static let backgroundGray = Color(red: 0.95, green: 0.95, blue: 0.97)
}

// MARK: - Data Models
struct User: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let email: String
    let avatar: URL?
    let createdAt: Date
    let isActive: Bool
    let metadata: [String: String]?
    
    init(name: String, email: String, avatar: URL? = nil, isActive: Bool = true) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.avatar = avatar
        self.createdAt = Date()
        self.isActive = isActive
        self.metadata = ["version": "1.0", "source": "manual"]
    }
    
    var displayName: String {
        return name.isEmpty ? "Unknown User" : name
    }
    
    static let sampleUsers: [User] = [
        User(name: "John Doe", email: "john@example.com"),
        User(name: "Jane Smith", email: "jane@example.com"),
        User(name: "Bob Johnson", email: "bob@example.com", isActive: false),
        User(name: "Alice Wilson", email: "alice@company.com"),
        User(name: "Charlie Brown", email: "charlie@peanuts.com")
    ]
}

struct APIResponse<T: Codable>: Codable {
    let data: T
    let message: String?
    let success: Bool
    let timestamp: Date
    let pagination: Pagination?
    
    struct Pagination: Codable {
        let page: Int
        let limit: Int
        let total: Int
        let hasNext: Bool
    }
}

// MARK: - Network Layer
class NetworkManager: ObservableObject, NetworkService {
    static let shared = NetworkManager()
    private let session = URLSession.shared
    private let baseURL = "https://api.example.com/v1"
    
    private init() {}
    
    func fetchData<T: Codable>(_ type: T.Type, from url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer token-12345", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.invalidResponse
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    func postData<T: Codable, U: Codable>(_ data: T, to url: URL, expecting type: U.Type) async throws -> U {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(data)
        } catch {
            throw NetworkError.encodingFailed(error)
        }
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(type, from: responseData)
    }
}

enum NetworkError: Error, LocalizedError, CaseIterable {
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case encodingFailed(Error)
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidResponse:
            return "Invalid server response"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network is unavailable"
        }
    }
    
    static var allCases: [NetworkError] {
        return [.invalidURL, .invalidResponse, .networkUnavailable]
    }
}

// MARK: - View Models
@MainActor
class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var sortOption: SortOption = .name
    @Published var filterOption: FilterOption = .all
    
    private let networkService: NetworkService
    private var cancellables = Set<AnyCancellable>()
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case email = "Email"
        case date = "Date Created"
        
        func sort(_ users: [User]) -> [User] {
            switch self {
            case .name:
                return users.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            case .email:
                return users.sorted { $0.email.localizedCaseInsensitiveCompare($1.email) == .orderedAscending }
            case .date:
                return users.sorted { $0.createdAt > $1.createdAt }
            }
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All Users"
        case active = "Active Only"
        case inactive = "Inactive Only"
        
        func filter(_ users: [User]) -> [User] {
            switch self {
            case .all:
                return users
            case .active:
                return users.filter { $0.isActive }
            case .inactive:
                return users.filter { !$0.isActive }
            }
        }
    }
    
    init(networkService: NetworkService = NetworkManager.shared) {
        self.networkService = networkService
        setupSearch()
    }
    
    var filteredAndSortedUsers: [User] {
        let searchFiltered = searchText.isEmpty ? users : users.filter { user in
            user.name.localizedCaseInsensitiveContains(searchText) ||
            user.email.localizedCaseInsensitiveContains(searchText)
        }
        
        let statusFiltered = filterOption.filter(searchFiltered)
        return sortOption.sort(statusFiltered)
    }
    
    private func setupSearch() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func fetchUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulated network delay
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            // Simulate potential network error (10% chance)
            if Int.random(in: 1...10) == 1 {
                throw NetworkError.networkUnavailable
            }
            
            users = User.sampleUsers
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addUser(_ user: User) {
        users.append(user)
        objectWillChange.send()
    }
    
    func updateUser(_ user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
        }
    }
    
    func deleteUser(at offsets: IndexSet) {
        users.remove(atOffsets: offsets)
    }
    
    func toggleUserStatus(_ user: User) {
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            let updatedUser = User(
                name: user.name,
                email: user.email,
                avatar: user.avatar,
                isActive: !user.isActive
            )
            users[index] = updatedUser
        }
    }
}

// MARK: - SwiftUI Views
struct ContentView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var showingAddUser = false
    @State private var selectedUser: User?
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchText)
                    .padding(.horizontal)
                
                FilterSortBar(
                    sortOption: $viewModel.sortOption,
                    filterOption: $viewModel.filterOption
                )
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.users.isEmpty {
                    EmptyStateView {
                        await viewModel.fetchUsers()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    UserListView(
                        users: viewModel.filteredAndSortedUsers,
                        onDelete: viewModel.deleteUser,
                        onToggleStatus: viewModel.toggleUserStatus
                    ) { user in
                        selectedUser = user
                    }
                }
            }
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                    
                    Button(action: {
                        showingAddUser = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await viewModel.fetchUsers()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .refreshable {
                await viewModel.fetchUsers()
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView { user in
                    viewModel.addUser(user)
                }
            }
            .sheet(item: $selectedUser) { user in
                UserDetailView(user: user) { updatedUser in
                    viewModel.updateUser(updatedUser)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Retry") {
                    Task {
                        await viewModel.fetchUsers()
                    }
                }
                Button("Dismiss", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            if viewModel.users.isEmpty {
                await viewModel.fetchUsers()
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search users...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct FilterSortBar: View {
    @Binding var sortOption: UserViewModel.SortOption
    @Binding var filterOption: UserViewModel.FilterOption
    
    var body: some View {
        HStack {
            Menu {
                ForEach(UserViewModel.SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                }
            } label: {
                HStack {
                    Text("Sort: \(sortOption.rawValue)")
                    Image(systemName: "chevron.down")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Menu {
                ForEach(UserViewModel.FilterOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        filterOption = option
                    }
                }
            } label: {
                HStack {
                    Text("Filter: \(filterOption.rawValue)")
                    Image(systemName: "chevron.down")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading users...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct EmptyStateView: View {
    let onRefresh: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Users Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the refresh button to load users")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await onRefresh()
                }
            }) {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.primaryAccent)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

struct UserListView: View {
    let users: [User]
    let onDelete: (IndexSet) -> Void
    let onToggleStatus: (User) -> Void
    let onUserTap: (User) -> Void
    
    var body: some View {
        List {
            ForEach(users) { user in
                UserRowView(
                    user: user,
                    onToggleStatus: { onToggleStatus(user) },
                    onTap: { onUserTap(user) }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(PlainListStyle())
    }
}

struct UserRowView: View {
    let user: User
    let onToggleStatus: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.primaryAccent.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(user.name.initials)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryAccent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(user.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    StatusBadge(isActive: user.isActive)
                }
            }
            
            Spacer()
            
            Button(action: onToggleStatus) {
                Image(systemName: user.isActive ? "pause.circle" : "play.circle")
                    .font(.title2)
                    .foregroundColor(user.isActive ? .orange : .green)
            }
        }
        .padding()
        .background(Color.backgroundGray)
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
}

struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isActive ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isActive ? "Active" : "Inactive")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(isActive ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((isActive ? Color.green : Color.red).opacity(0.1))
        .cornerRadius(8)
    }
}

struct AddUserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let onSave: (User) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("User Information") {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section {
                    Button("Save User") {
                        saveUser()
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.isValidEmail
    }
    
    private func saveUser() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showError("Please enter a name")
            return
        }
        
        guard trimmedEmail.isValidEmail else {
            showError("Please enter a valid email address")
            return
        }
        
        let newUser = User(name: trimmedName, email: trimmedEmail)
        onSave(newUser)
        dismiss()
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

struct UserDetailView: View {
    let user: User
    let onUpdate: (User) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryAccent.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Text(user.name.initials)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryAccent)
                        }
                        
                        Text(user.displayName)
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text(user.email)
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        StatusBadge(isActive: user.isActive)
                    }
                    .padding()
                    
                    // User Details
                    LazyVStack(spacing: 16) {
                        DetailRow(title: "User ID", value: user.id.uuidString)
                        DetailRow(title: "Created", value: user.createdAt.formatted(date: .abbreviated, time: .shortened))
                        DetailRow(title: "Status", value: user.isActive ? "Active" : "Inactive")
                        
                        if let metadata = user.metadata {
                            ForEach(Array(metadata.keys), id: \.self) { key in
                                DetailRow(title: key.capitalized, value: metadata[key] ?? "")
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("User Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(Color.backgroundGray)
        .cornerRadius(8)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("dark_mode_enabled") private var darkModeEnabled = false
    @AppStorage("auto_refresh") private var autoRefresh = true
    
    var body: some View {
        NavigationView {
            List {
                Section("Preferences") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                    Toggle("Auto Refresh", isOn: $autoRefresh)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2024.01.15")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview Providers
#Preview("ContentView") {
    ContentView()
}

#Preview("UserRowView") {
    UserRowView(
        user: User.sampleUsers[0],
        onToggleStatus: {},
        onTap: {}
    )
    .padding()
}

#Preview("AddUserView") {
    AddUserView { _ in }
}

#Preview("LoadingView") {
    LoadingView()
}

#Preview("EmptyStateView") {
    EmptyStateView {
        // Preview action
    }
}
