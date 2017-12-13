import Foundation
import Kitura
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public struct Memo: Codable {
    public var id: Int?
    public var text: String?
}

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()

    private var nextID = 0
    private var memos = [Int: Memo]()

    public init() throws {
    }

    func postInit() throws {
        initializeMetrics(app: self)
        initializeHealthRoutes(app: self)

        router.post("/memos") { (memo: Memo, respondWith: (Memo?, RequestError?) -> Void) in
            let id = self.nextID
            self.nextID += 1

            let new = Memo(id: id, text: memo.text)
            self.memos[id] = new

            respondWith(new, nil)
        }

        router.get("/memos") { (respondWith: ([Memo]?, RequestError?) -> Void) in
            respondWith(self.memos.values.map({ $0 }), nil)
        }

        router.get("/memos") { (id: Int, respondWith: (Memo?, RequestError?) -> Void) in
            if let memo = self.memos[id] {
                respondWith(memo, nil)
            } else {
                respondWith(nil, .notFound)
            }
        }

        router.put("/memos") { (id: Int, memo: Memo, respondWith: (Memo?, RequestError?) -> Void) in
            if self.memos[id] != nil {
                let modified = Memo(id: id, text: memo.text)
                self.memos[id] = modified
                respondWith(modified, nil)
            } else {
                respondWith(nil, .notFound)
            }
        }
        
        router.delete("/memos") { (id: Int, respondWith: (RequestError?) -> Void) in
            if self.memos[id] != nil {
                self.memos.removeValue(forKey: id)
                respondWith(nil)
            } else {
                respondWith(.notFound)
            }
        }
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
