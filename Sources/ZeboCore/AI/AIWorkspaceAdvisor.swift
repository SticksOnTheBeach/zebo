import Foundation

/// Demande à une IA quels dossiers servent de workspace pour un genre de projet.
public struct AIWorkspaceAdvisor: WorkspaceAdvisor {
    private let client: any AIClient

    public init(client: any AIClient) {
        self.client = client
    }

    public func adviseWorkspaces(for kind: ProjectKind, among folders: [FolderSummary]) async throws
        -> WorkspaceAdvice
    {
        let candidates = Array(folders.prefix(WorkspaceQuestion.maxFolders))
        let prompt = AIPrompt(
            instructions: WorkspaceQuestion.instructions,
            messages: [.user(try WorkspaceQuestion.prompt(for: kind, among: candidates))],
            format: WorkspaceQuestion.format, maxTokens: 8192)
        let json = try await client.answer(prompt)
        return try WorkspaceQuestion.advice(fromJSON: json, candidates: candidates, provider: client.provider)
    }
}
