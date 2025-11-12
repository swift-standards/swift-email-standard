import Foundation
@_exported import EmailAddress
@_exported import RFC_2045
@_exported import RFC_2046

/// A type-safe email message
///
/// Represents a complete email message with addresses, subject, body content,
/// and headers. Built on RFC standards for proper email formatting.
///
/// ## Example
///
/// ```swift
/// // Simple HTML email
/// let email = try Email(
///     to: [EmailAddress("recipient@example.com")],
///     from: EmailAddress("sender@example.com"),
///     subject: "Hello!",
///     html: "<h1>Hello, World!</h1>"
/// )
///
/// // Email with text and HTML alternatives
/// let email = try Email(
///     to: [EmailAddress("recipient@example.com")],
///     from: EmailAddress("sender@example.com"),
///     subject: "Newsletter",
///     text: "Plain text version",
///     html: "<h1>HTML version</h1>"
/// )
/// ```
///
/// This module re-exports EmailAddress, RFC 2045, and RFC 2046 for convenience.
public struct Email: Hashable, Sendable {
    /// Recipient addresses
    public let to: [EmailAddress]

    /// Sender address
    public let from: EmailAddress

    /// Reply-to address (if different from sender)
    public let replyTo: EmailAddress?

    /// Carbon copy addresses
    public let cc: [EmailAddress]?

    /// Blind carbon copy addresses
    public let bcc: [EmailAddress]?

    /// Email subject line
    public let subject: String

    /// Email body content
    public let body: Body

    /// Additional custom headers
    public let headers: [String: String]

    /// Creates an email message
    ///
    /// - Parameters:
    ///   - to: Recipient addresses (must not be empty)
    ///   - from: Sender address
    ///   - replyTo: Reply-to address (optional)
    ///   - cc: Carbon copy addresses (optional)
    ///   - bcc: Blind carbon copy addresses (optional)
    ///   - subject: Email subject
    ///   - body: Email body content
    ///   - headers: Additional custom headers (optional)
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        replyTo: EmailAddress? = nil,
        cc: [EmailAddress]? = nil,
        bcc: [EmailAddress]? = nil,
        subject: String,
        body: Body,
        headers: [String: String] = [:]
    ) throws {
        guard !to.isEmpty else {
            throw Email.Error.emptyRecipients
        }

        self.to = to
        self.from = from
        self.replyTo = replyTo
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.body = body
        self.headers = headers
    }

    /// All MIME headers including Content-Type
    ///
    /// Combines custom headers with MIME headers from the body.
    public var allHeaders: [String: String] {
        var result = headers
        result["Content-Type"] = body.contentType.headerValue
        if let encoding = body.transferEncoding {
            result["Content-Transfer-Encoding"] = encoding.headerValue
        }
        return result
    }
}

// MARK: - Error

extension Email {
    /// Email validation errors
    public enum Error: Swift.Error, Hashable, Sendable {
        /// The recipient list is empty
        case emptyRecipients
    }
}

extension Email.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyRecipients:
            return "Email must have at least one recipient in the 'to' field"
        }
    }
}

// MARK: - Body

extension Email {
    /// Email body content
    ///
    /// Supports plain text, HTML, or multipart (text + HTML) content.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Plain text
    /// let body = Email.Body.text("Hello!")
    ///
    /// // HTML
    /// let body = Email.Body.html("<h1>Hello!</h1>")
    ///
    /// // Text + HTML alternative
    /// let body = try Email.Body.multipart(
    ///     .alternative(
    ///         textContent: "Hello!",
    ///         htmlContent: "<h1>Hello!</h1>"
    ///     )
    /// )
    /// ```
    public enum Body: Hashable, Sendable {
        /// Plain text content
        case text(String, charset: String = "UTF-8")

        /// HTML content
        case html(String, charset: String = "UTF-8")

        /// Multipart message (text + HTML alternatives, attachments, etc.)
        case multipart(RFC_2046.Multipart)

        /// The Content-Type for this body
        public var contentType: RFC_2045.ContentType {
            switch self {
            case .text(_, let charset):
                return RFC_2045.ContentType(
                    type: "text",
                    subtype: "plain",
                    parameters: ["charset": charset]
                )

            case .html(_, let charset):
                return RFC_2045.ContentType(
                    type: "text",
                    subtype: "html",
                    parameters: ["charset": charset]
                )

            case .multipart(let multipart):
                return multipart.contentType
            }
        }

        /// The Content-Transfer-Encoding for this body (if needed)
        public var transferEncoding: RFC_2045.ContentTransferEncoding? {
            switch self {
            case .text, .html:
                return .sevenBit
            case .multipart:
                return nil  // Multipart doesn't have transfer encoding at top level
            }
        }

        /// Renders the body content as a string
        ///
        /// For multipart bodies, this includes the complete MIME structure
        /// with boundaries.
        public func render() -> String {
            switch self {
            case .text(let content, _):
                return content

            case .html(let content, _):
                return content

            case .multipart(let multipart):
                return multipart.render()
            }
        }

        /// The rendered body content
        public var content: String {
            render()
        }
    }
}

// MARK: - Convenience Initializers

extension Email {
    /// Creates an email with simple text content
    ///
    /// - Parameters:
    ///   - to: Recipient addresses
    ///   - from: Sender address
    ///   - subject: Email subject
    ///   - text: Plain text content
    ///   - headers: Additional headers
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        subject: String,
        text: String,
        headers: [String: String] = [:]
    ) throws {
        try self.init(
            to: to,
            from: from,
            subject: subject,
            body: .text(text),
            headers: headers
        )
    }

    /// Creates an email with simple HTML content
    ///
    /// - Parameters:
    ///   - to: Recipient addresses
    ///   - from: Sender address
    ///   - subject: Email subject
    ///   - html: HTML content
    ///   - headers: Additional headers
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        subject: String,
        html: String,
        headers: [String: String] = [:]
    ) throws {
        try self.init(
            to: to,
            from: from,
            subject: subject,
            body: .html(html),
            headers: headers
        )
    }

    /// Creates an email with both text and HTML content
    ///
    /// - Parameters:
    ///   - to: Recipient addresses
    ///   - from: Sender address
    ///   - subject: Email subject
    ///   - text: Plain text content
    ///   - html: HTML content
    ///   - headers: Additional headers
    /// - Throws: `Email.Error.emptyRecipients` if the `to` array is empty
    public init(
        to: [EmailAddress],
        from: EmailAddress,
        subject: String,
        text: String,
        html: String,
        headers: [String: String] = [:]
    ) throws {
        try self.init(
            to: to,
            from: from,
            subject: subject,
            body: .multipart(try .alternative(textContent: text, htmlContent: html)),
            headers: headers
        )
    }
}

// MARK: - Protocol Conformances

extension Email: Codable {
    enum CodingKeys: String, CodingKey {
        case to, from, replyTo, cc, bcc, subject, body, headers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.to = try container.decode([EmailAddress].self, forKey: .to)
        self.from = try container.decode(EmailAddress.self, forKey: .from)
        self.replyTo = try container.decodeIfPresent(EmailAddress.self, forKey: .replyTo)
        self.cc = try container.decodeIfPresent([EmailAddress].self, forKey: .cc)
        self.bcc = try container.decodeIfPresent([EmailAddress].self, forKey: .bcc)
        self.subject = try container.decode(String.self, forKey: .subject)
        self.body = try container.decode(Body.self, forKey: .body)
        self.headers = try container.decode([String: String].self, forKey: .headers)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(to, forKey: .to)
        try container.encode(from, forKey: .from)
        try container.encodeIfPresent(replyTo, forKey: .replyTo)
        try container.encodeIfPresent(cc, forKey: .cc)
        try container.encodeIfPresent(bcc, forKey: .bcc)
        try container.encode(subject, forKey: .subject)
        try container.encode(body, forKey: .body)
        try container.encode(headers, forKey: .headers)
    }
}

extension Email.Body: Codable {
    enum CodingKeys: String, CodingKey {
        case type, content, charset, multipart
    }

    enum BodyType: String, Codable {
        case text, html, multipart
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BodyType.self, forKey: .type)

        switch type {
        case .text:
            let content = try container.decode(String.self, forKey: .content)
            let charset = try container.decode(String.self, forKey: .charset)
            self = .text(content, charset: charset)

        case .html:
            let content = try container.decode(String.self, forKey: .content)
            let charset = try container.decode(String.self, forKey: .charset)
            self = .html(content, charset: charset)

        case .multipart:
            let multipart = try container.decode(RFC_2046.Multipart.self, forKey: .multipart)
            self = .multipart(multipart)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let content, let charset):
            try container.encode(BodyType.text, forKey: .type)
            try container.encode(content, forKey: .content)
            try container.encode(charset, forKey: .charset)

        case .html(let content, let charset):
            try container.encode(BodyType.html, forKey: .type)
            try container.encode(content, forKey: .content)
            try container.encode(charset, forKey: .charset)

        case .multipart(let multipart):
            try container.encode(BodyType.multipart, forKey: .type)
            try container.encode(multipart, forKey: .multipart)
        }
    }
}
