import Foundation

/// Ce que les clients des IA ont en commun : construire une requête JSON et l'envoyer.
enum AIHTTP {
    /// Le message d'erreur d'une API (`{"error": {"message": …}}`, format commun à toutes).
    static func errorMessage(in data: Data) -> String {
        struct ErrorBody: Decodable {
            struct Detail: Decodable { let message: String }
            let error: Detail
        }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message ?? ""
    }

    /// Envoie la requête ; une réponse autre que 200 devient une erreur claire.
    static func send(_ request: URLRequest, with transport: any HTTPTransport) async throws -> Data {
        let (data, response) = try await transport.send(request)
        guard response.statusCode == 200 else {
            throw AIFailure.http(status: response.statusCode, message: errorMessage(in: data))
        }
        return data
    }

    static func jsonRequest(url: URL, headers: [String: String], body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        for (field, value) in headers { request.setValue(value, forHTTPHeaderField: field) }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    static func url(_ string: String) -> URL {
        guard let url = URL(string: string) else { preconditionFailure("Adresse d'API invalide : \(string)") }
        return url
    }
}
