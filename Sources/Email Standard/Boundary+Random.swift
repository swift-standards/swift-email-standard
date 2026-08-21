import RFC_2046
import RFC_4648

extension RFC_2046.Boundary {

    public static func random() -> Self {
        let randomBytes = (0..<16).map { _ in Byte(UInt8.random(in: 0...255)) }
        let hexBytes: [ASCII.Code] = RFC_4648.Hex.encode(randomBytes, uppercase: false)
        let hex = String(decoding: hexBytes, as: UTF8.self)

        return try! Self("----=_Part_\(hex)")
    }
}
