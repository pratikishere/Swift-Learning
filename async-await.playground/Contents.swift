import UIKit

enum NetworkError: Error {
    case badUrl
    case decodingError
    case invalidUserId
}

struct CreditScore: Decodable {
    let scores: [Int]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        scores = try container.decode([Int].self)
    }
}

struct Constants {
    struct Urls {
        static func equifax(userId: Int) -> URL? {
            return URL(string: "http://www.randomnumberapi.com/api/v1.0/random?min=100&max=1000")
        }
        
        static func experian(userId: Int) -> URL? {
            return URL(string: "http://www.randomnumberapi.com/api/v1.0/random?min=100&max=1000")
        }
    }
}

func calculateAPR(creditScores: [CreditScore]) -> Double {
    let sum = creditScores.reduce(0) { next, credit in
        return next + credit.scores.first!
    }
    // Calculate the APR based on the scores
    return Double((sum/creditScores.count)/100)
}

func getAPR(userId: Int) async throws -> Double {
    
    if userId % 2 == 0 {
        throw NetworkError.invalidUserId
    }
    
    guard let equifaxUrl = Constants.Urls.equifax(userId: userId),
          let experianUrl = Constants.Urls.experian(userId: userId)
    else {
        throw NetworkError.badUrl
    }
    
    async let (equifaxData, _) = URLSession.shared.data(from: equifaxUrl)
    async let (experianData, _) = URLSession.shared.data(from: experianUrl)
    
    let equifaxCreditScore = try? JSONDecoder().decode(CreditScore.self, from: try await equifaxData)
    let experianCreditScore = try? JSONDecoder().decode(CreditScore.self, from: try await experianData)
    
    guard let equifaxCreditScore, let experianCreditScore
    else {
        throw NetworkError.decodingError
    }
    
    return calculateAPR(creditScores: [equifaxCreditScore, experianCreditScore])
}

let ids = [1,2,3,4,5,6,7,8,9,10]

// Serial Task Execution
func getAPRForUserIdsSerially() {
    Task {
        for id in ids {
            do {
                let apr = try await getAPR(userId: id)
                print(apr)
            } catch {
                print("Error fethcing APR for user \(id): \(error)")
            }
        }
    }
}

getAPRForUserIdsSerially()

