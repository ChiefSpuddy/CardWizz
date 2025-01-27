class UserRepository {
    // ...existing code...
    
    func findOrCreateUser(id: String, email: String, appleIdentifier: String) async throws -> User {
        // First try to find user by Apple identifier
        if let user = try await findUserByAppleIdentifier(appleIdentifier) {
            return user
        }
        
        // Then try by email
        if let user = try await findUserByEmail(email) {
            // Update the user's Apple identifier
            try await updateUserAppleIdentifier(user: user, appleIdentifier: appleIdentifier)
            return user
        }
        
        // Create new user if not found
        return try await createUser(id: id, email: email, appleIdentifier: appleIdentifier)
    }
    
    private func findUserByAppleIdentifier(_ identifier: String) async throws -> User? {
        let query = users.whereField("appleIdentifier", isEqualTo: identifier)
        let snapshot = try await query.getDocuments()
        return snapshot.documents.first.map { User(from: $0) }
    }
    
    private func updateUserAppleIdentifier(user: User, appleIdentifier: String) async throws {
        try await users.document(user.id).updateData([
            "appleIdentifier": appleIdentifier
        ])
    }
    // ...existing code...
}
