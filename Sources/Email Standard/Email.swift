@_exported import EmailAddress_Standard
@_exported import RFC_2045
@_exported import RFC_2046
@_exported import RFC_5322

public struct Email: Hashable, Sendable, CustomDebugStringConvertible {

    public let to: [EmailAddress]

    public let from: EmailAddress

    public let replyTo: EmailAddress?

    public let cc: [EmailAddress]?

    public let bcc: [EmailAddress]?

    public let date: RFC_5322.DateTime

    public let subject: String

    public let body: Body

    public let additionalHeaders: [RFC_5322.Header]

    public init(
        to: [EmailAddress],
        from: EmailAddress,
        replyTo: EmailAddress? = nil,
        cc: [EmailAddress]? = nil,
        bcc: [EmailAddress]? = nil,
        date: RFC_5322.DateTime,
        subject: some StringProtocol,
        body: Body,
        additionalHeaders: [RFC_5322.Header] = []
    ) throws(Error) {
        guard !to.isEmpty else {
            throw .emptyRecipients
        }

        self.to = to
        self.from = from
        self.replyTo = replyTo
        self.cc = cc
        self.bcc = bcc
        self.date = date
        self.subject = String(subject)
        self.body = body
        self.additionalHeaders = additionalHeaders
    }

    public var allHeaders: [RFC_5322.Header] {
        var result = additionalHeaders
        result[.contentType] = body.contentType.description
        if let encoding = body.transferEncoding {
            result[.contentTransferEncoding] = encoding.description
        }
        return result
    }
}

extension Email {

    public enum Error: Swift.Error, Hashable, Sendable {

        case emptyRecipients

        case multipart(RFC_2046.Multipart.Error)
    }
}

extension Email.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyRecipients:
            return "Email must have at least one recipient in the 'to' field"

        case .multipart(let error):
            return "Failed to construct multipart body: \(error)"
        }
    }
}

extension Email {

    public enum Body: Hashable, Sendable {

        case text([UInt8], charset: RFC_2045.Charset)

        case html([UInt8], charset: RFC_2045.Charset)

        case multipart(RFC_2046.Multipart)

        public var contentType: RFC_2045.ContentType {
            switch self {
            case .text(_, let charset):
                return RFC_2045.ContentType(
                    __unchecked: (),
                    type: "text",
                    subtype: "plain",
                    parameters: [.charset: charset.rawValue]
                )

            case .html(_, let charset):
                return RFC_2045.ContentType(
                    __unchecked: (),
                    type: "text",
                    subtype: "html",
                    parameters: [.charset: charset.rawValue]
                )

            case .multipart(let multipart):
                return multipart.contentType
            }
        }

        public var transferEncoding: RFC_2045.ContentTransferEncoding? {
            switch self {
            case .text, .html:
                return .sevenBit

            case .multipart:
                return nil
            }
        }

        public func render() -> String {
            switch self {
            case .text(let data, _):
                return String(decoding: data, as: UTF8.self)

            case .html(let data, _):
                return String(decoding: data, as: UTF8.self)

            case .multipart(let multipart):
                return String(multipart)
            }
        }

        public var content: String {
            render()
        }

        public var data: [UInt8] {
            switch self {
            case .text(let data, _), .html(let data, _):
                return data

            case .multipart(let multipart):
                return [UInt8](multipart)
            }
        }
    }
}

extension Email.Body {

    public static func text(
        _ content: some StringProtocol,
        charset: RFC_2045.Charset = .utf8
    ) -> Self {
        .text(Array(content.utf8), charset: charset)
    }

    public static func html(
        _ content: some StringProtocol,
        charset: RFC_2045.Charset = .utf8
    ) -> Self {
        .html(Array(content.utf8), charset: charset)
    }

    public static func textData(_ content: [UInt8], charset: RFC_2045.Charset = .utf8) -> Self {
        .text(content, charset: charset)
    }

    public static func htmlData(_ content: [UInt8], charset: RFC_2045.Charset = .utf8) -> Self {
        .html(content, charset: charset)
    }
}

extension Email.Body: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self = .text(value)
    }
}

extension Email {

    public init(
        to: [EmailAddress],
        from: EmailAddress,
        subject: some StringProtocol,
        text: some StringProtocol,
        date: RFC_5322.DateTime,
        additionalHeaders: [RFC_5322.Header] = []
    ) throws(Error) {
        try self.init(
            to: to,
            from: from,
            date: date,
            subject: String(subject),
            body: .text(text),
            additionalHeaders: additionalHeaders
        )
    }

    public init(
        to: [EmailAddress],
        from: EmailAddress,
        subject: some StringProtocol,
        html: some StringProtocol,
        date: RFC_5322.DateTime,
        additionalHeaders: [RFC_5322.Header] = []
    ) throws(Error) {
        try self.init(
            to: to,
            from: from,
            date: date,
            subject: String(subject),
            body: .html(html),
            additionalHeaders: additionalHeaders
        )
    }

    public init(
        to: [EmailAddress],
        from: EmailAddress,
        subject: some StringProtocol,
        text: some StringProtocol,
        html: some StringProtocol,
        date: RFC_5322.DateTime,
        additionalHeaders: [RFC_5322.Header] = []
    ) throws(Error) {
        let multipart: RFC_2046.Multipart
        do {
            multipart = try .alternative(textContent: text, htmlContent: html)
        } catch {
            throw .multipart(error)
        }
        try self.init(
            to: to,
            from: from,
            date: date,
            subject: String(subject),
            body: .multipart(multipart),
            additionalHeaders: additionalHeaders
        )
    }
}

extension Email {

    public var debugDescription: String {
        let recipients = to.map(\.address).joined(separator: ", ")
        var parts = ["From: \(from.address)", "To: \(recipients)"]

        if let replyTo {
            parts.append("Reply-To: \(replyTo.address)")
        }
        if let cc, !cc.isEmpty {
            parts.append("CC: \(cc.map(\.address).joined(separator: ", "))")
        }
        if let bcc, !bcc.isEmpty {
            parts.append("BCC: \(bcc.map(\.address).joined(separator: ", "))")
        }

        parts.append("Subject: \"\(subject)\"")

        return parts.joined(separator: " ")
    }
}

extension Email: Codable {
    enum CodingKeys: String, CodingKey {
        case to, from, replyTo, cc, bcc, date, subject, body, additionalHeaders
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.to = try container.decode([EmailAddress].self, forKey: .to)
        self.from = try container.decode(EmailAddress.self, forKey: .from)
        self.replyTo = try container.decodeIfPresent(EmailAddress.self, forKey: .replyTo)
        self.cc = try container.decodeIfPresent([EmailAddress].self, forKey: .cc)
        self.bcc = try container.decodeIfPresent([EmailAddress].self, forKey: .bcc)
        self.date = try container.decode(RFC_5322.DateTime.self, forKey: .date)
        self.subject = try container.decode(String.self, forKey: .subject)
        self.body = try container.decode(Body.self, forKey: .body)
        self.additionalHeaders = try container.decode(
            [RFC_5322.Header].self,
            forKey: .additionalHeaders
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(to, forKey: .to)
        try container.encode(from, forKey: .from)
        try container.encodeIfPresent(replyTo, forKey: .replyTo)
        try container.encodeIfPresent(cc, forKey: .cc)
        try container.encodeIfPresent(bcc, forKey: .bcc)
        try container.encode(date, forKey: .date)
        try container.encode(subject, forKey: .subject)
        try container.encode(body, forKey: .body)
        try container.encode(additionalHeaders, forKey: .additionalHeaders)
    }
}

extension Email.Body: Codable {
    enum CodingKeys: String, CodingKey {
        case type, content, charset, multipart
    }

    enum BodyType: String, Codable {
        case text, html, multipart
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BodyType.self, forKey: .type)

        switch type {
        case .text:
            let content = try container.decode([UInt8].self, forKey: .content)
            let charset = try container.decode(RFC_2045.Charset.self, forKey: .charset)
            self = .text(content, charset: charset)

        case .html:
            let content = try container.decode([UInt8].self, forKey: .content)
            let charset = try container.decode(RFC_2045.Charset.self, forKey: .charset)
            self = .html(content, charset: charset)

        case .multipart:
            let multipart = try container.decode(RFC_2046.Multipart.self, forKey: .multipart)
            self = .multipart(multipart)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let data, let charset):
            try container.encode(BodyType.text, forKey: .type)
            try container.encode(data, forKey: .content)
            try container.encode(charset, forKey: .charset)

        case .html(let data, let charset):
            try container.encode(BodyType.html, forKey: .type)
            try container.encode(data, forKey: .content)
            try container.encode(charset, forKey: .charset)

        case .multipart(let multipart):
            try container.encode(BodyType.multipart, forKey: .type)
            try container.encode(multipart, forKey: .multipart)
        }
    }
}
