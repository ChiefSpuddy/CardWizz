class AuthService {
    // ...existing code...
    
    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async throws -> User {
        let email = credential.email ?? credential.user
        let userIdentifier = credential.user
        
        // Store both real email and private relay email
        let user = try await userRepository.findOrCreateUser(
            id: userIdentifier,
            email: email,
            appleIdentifier: credential.user
        )
        
        return user
    }
    // ...existing code...
}
