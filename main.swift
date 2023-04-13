import Foundation 

extension String {
    mutating func encodeToBase64() {
        let encodedString = Data(self.utf8).base64EncodedString()
        self = encodedString
    }
}

class ClientConfig: Codable {
    public var client_id: String
    public var client_secret: String
}


class APIResponse: Decodable {
    public var access_token: String
    public var token_type: String 
    public var expires_in: Int
}


class APIErrorResponse: Decodable {
    public var error: String
    public var error_description: String
}


func readClientConfigFile() -> ClientConfig? {
    guard let filePath = Bundle.main.url(forResource: "ClientConfig", withExtension: "json") else {
        print("Could not open file.")
        return nil
    }
    guard let jsonData = try? Data(contentsOf: filePath) else {
        print("Could not read contents of file")
        return nil
    }
    guard let decodedData = try? JSONDecoder().decode(ClientConfig.self, from: jsonData) else {
        print("Could not decode data")
        return nil
    }
    return decodedData
}


// Make a request
func getAccessToken(clientConfig: ClientConfig) async -> String? {
    let apiEndpoint = URL(string: "https://accounts.spotify.com/api/token")! // https://accounts.spotify.com/api/token
    var httpRequest = URLRequest(url: apiEndpoint)
    httpRequest.httpMethod = "POST"
    var encodedAuth = "\(clientConfig.client_id):\(clientConfig.client_secret)"
    encodedAuth.encodeToBase64()
    httpRequest.addValue("Basic \(encodedAuth)", forHTTPHeaderField: "Authorization")
    httpRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

    // Since we are using application/x-www-form-urlencoded, we cannot just use JSONEncoder to encode an object
    var requestBody = URLComponents()
    let grantType = URLQueryItem(name: "grant_type", value: "client_credentials")
    requestBody.queryItems = [grantType]
    httpRequest.httpBody = requestBody.query?.data(using: .utf8)

    do {
        let (responseBody, responseHeader) = try await URLSession.shared.data(for: httpRequest)
        let httpURLResponseHeader = responseHeader as! HTTPURLResponse
        if httpURLResponseHeader.statusCode != 200 {
            print("Server responded with code: ", httpURLResponseHeader.statusCode)
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: responseBody) {
                print("error: \(apiError.error)")
                print("error_description: \(apiError.error_description)")
            } else {
                print("Could not decode response body")
            }

            return nil
        }
        guard let decodedData = try? JSONDecoder().decode(APIResponse.self, from: responseBody)  else {
            print("Could not decode server response.")
            return nil
        } // Decode the body data
        return decodedData.access_token
    } catch let error {
        print(error.localizedDescription)
        return nil
    }
}


func main() async -> Void {
    guard let clientConfig = readClientConfigFile() else {
        exit(1)
    }
    guard let accessToken = await getAccessToken(clientConfig: clientConfig) else {
        exit(1)
    }
    print("Successfully obtained access token: ")
    print(accessToken)
    exit(0)
}

await main()
