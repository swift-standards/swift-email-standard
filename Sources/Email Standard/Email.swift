public import Byte
public import EmailAddress_Standard
public import RFC_2045
public import RFC_2046
public import RFC_5322
import RFC_2045_Coder

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

        case text([Byte], charset: RFC_2045.Charset)

        case html([Byte], charset: RFC_2045.Charset)

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
    }
}

extension Email.Body {

    public static func text(
        _ content: some StringProtocol,
        charset: RFC_2045.Charset = .utf8
    ) -> Self {
        .text(content.utf8.map(Byte.init(bitPattern:)), charset: charset)
    }

    public static func html(
        _ content: some StringProtocol,
        charset: RFC_2045.Charset = .utf8
    ) -> Self {
        .html(content.utf8.map(Byte.init(bitPattern:)), charset: charset)
    }

    public static func textData(_ content: [Byte], charset: RFC_2045.Charset = .utf8) -> Self {
        .text(content, charset: charset)
    }

    public static func htmlData(_ content: [Byte], charset: RFC_2045.Charset = .utf8) -> Self {
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
