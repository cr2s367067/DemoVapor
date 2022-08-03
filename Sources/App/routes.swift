import Fluent
import Vapor

struct MessageRequest: Content {
    var userName: String
    var firstDiastolic: String
    var secondDiastolic: String
    var firstSystolic: String
    var secondSystolic: String
    var firstPulse: String
    var secondPulse: String
}

struct CalResult: Content {
    var encryptName: String
    var avgDiastolic: String
    var avgSystolic: String
    var avgPulse: String
    var pressureStatus: BloodStatus.RawValue
}

extension CalResult {
    static let empty = CalResult(encryptName: "", avgDiastolic: "", avgSystolic: "", avgPulse: "", pressureStatus: "血壓過高，請就醫")
}

enum BloodStatus: String {
    case high = "血壓過高，請就醫"
    case normal = "血壓正常"
    case low = "血壓過低，請就醫"
}

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("echo") { req async -> String in
        if let body = req.body.string {
            return body.description
        }
        return req.description
    }
    
    app.post("bloodCal", use: startCompute)
    
//    app.post("bloodCal") { req async -> CalResult in
//        do {
//            print(req.description)
//            let data = try req.content.decode(MessageRequest.self)
//            return bloodAvgWithWarning(model: data)
//        } catch {
//            print("Error")
//        }
//        return .empty
//    }
    

    try app.register(collection: TodoController())
}

func startCompute(req: Request) async throws -> CalResult {
    print(req.description)
    let data = try req.content.decode(MessageRequest.self)
    print(data)
    return bloodAvgWithWarning(model: data)
}


func bloodAvgWithWarning(model input: MessageRequest) -> CalResult {
    
    var notice: BloodStatus = .normal
    
    let encryptName = nameEncrypt(user: input.userName)
    
    let convertFD = convertInt(input: input.firstDiastolic)
    let convertSD = convertInt(input: input.secondDiastolic)
    let convertFS = convertInt(input: input.firstSystolic)
    let convertSS = convertInt(input: input.secondSystolic)
    let convertFP = convertInt(input: input.firstPulse)
    let convertSP = convertInt(input: input.secondPulse)
    
    let avgDiastolic = getAvg(first: convertFD, second: convertSD)
    let avgSystolic = getAvg(first: convertFS, second: convertSS)
    let avgPulse = getAvg(first: convertFP, second: convertSP)
    
    if (Int(avgDiastolic) ?? 0 > 140) && (Int(avgSystolic) ?? 0 > 80) {
        notice = .high
    }
    
    if (Int(avgDiastolic) ?? 0 < 90) && (Int(avgSystolic) ?? 0 > 60) {
        notice = .low
    }
    
//     "使用者: \(encryptName)" + " 平均收縮壓: \(avgDiastolic)" + " 平均舒張壓: \(avgSystolic)" + " 平均脈搏: \(avgPulse)" + " 血壓狀態: \(notice.rawValue)"
    return CalResult(encryptName: encryptName, avgDiastolic: avgDiastolic, avgSystolic: avgSystolic, avgPulse: avgPulse, pressureStatus: notice.rawValue)
}

private func convertInt(input: String) -> Int {
    return Int(input) ?? 0
}

private func getAvg(first: Int, second: Int) -> String {
    let avgResult = abs((first + second) / 2)
    return String(avgResult)
}

private func nameEncrypt(user name: String) -> String {
    var hasher = Hasher()
    hasher.combine(name)
    let hash = hasher.finalize().description.base64Bytes().base64
    print("userName: \(name), encryptResult: \(hash)")
    return hash
}
