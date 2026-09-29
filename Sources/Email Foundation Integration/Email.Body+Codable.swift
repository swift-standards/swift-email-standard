public import Email_Standard
import Byte
import RFC_2045
import RFC_2045_Foundation_Integration
import RFC_2046
import RFC_2046_Foundation_Integration

extension Email.Body: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case type, content, charset, multipart
    }

    private enum Kind: String, Encodable, Decodable {
        case text, html, multipart
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        switch try container.decode(Kind.self, forKey: .type) {
        case .text:
            let octets = try container.decode([UInt8].self, forKey: .content)
            let charset = try container.decode(RFC_2045.Charset.self, forKey: .charset)
            self = .text(octets.map(Byte.init(bitPattern:)), charset: charset)

        case .html:
            let octets = try container.decode([UInt8].self, forKey: .content)
            let charset = try container.decode(RFC_2045.Charset.self, forKey: .charset)
            self = .html(octets.map(Byte.init(bitPattern:)), charset: charset)

        case .multipart:
            self = .multipart(try container.decode(RFC_2046.Multipart.self, forKey: .multipart))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let bytes, let charset):
            try container.encode(Kind.text, forKey: .type)
            try container.encode(bytes.map(\.bitPattern), forKey: .content)
            try container.encode(charset, forKey: .charset)

        case .html(let bytes, let charset):
            try container.encode(Kind.html, forKey: .type)
            try container.encode(bytes.map(\.bitPattern), forKey: .content)
            try container.encode(charset, forKey: .charset)

        case .multipart(let multipart):
            try container.encode(Kind.multipart, forKey: .type)
            try container.encode(multipart, forKey: .multipart)
        }
    }
}
