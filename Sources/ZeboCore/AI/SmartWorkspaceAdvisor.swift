import Foundation

/// L'IA choisie s'il y a une clé pour elle, sinon (ou si elle n'a pas pu répondre) la détection locale.
public struct SmartWorkspaceAdvisor: WorkspaceAdvisor {
    private let provider: AIProvider?
    private let model: String?
    private let keyStore: any APIKeyStore
    private let transport: any HTTPTransport
    private let fallback = LocalWorkspaceAdvisor()

    public init(
        provider: AIProvider?, model: String? = nil, keyStore: any APIKeyStore,
        transport: any HTTPTransport = URLSessionTransport()
    ) {
        self.provider = provider
        self.model = model
        self.keyStore = keyStore
        self.transport = transport
    }

    public func adviseWorkspaces(for kind: ProjectKind, among folders: [FolderSummary]) async -> WorkspaceAdvice {
        if let provider, let key = keyStore.readKey(for: provider), !key.isEmpty {
            let advisor = AIWorkspaceAdvisor(
                client: provider.makeClient(apiKey: key, model: model, transport: transport))
            if let advice = try? await advisor.adviseWorkspaces(for: kind, among: folders) {
                return advice
            }
        }
        return await fallback.adviseWorkspaces(for: kind, among: folders)
    }
}
