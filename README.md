# swift-email-standard

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
[![CI](https://github.com/swift-standards/swift-email-standard/workflows/CI/badge.svg)](https://github.com/swift-standards/swift-email-standard/actions/workflows/ci.yml)

Type-safe email message representation built on RFC standards

## Overview

This package provides a Swift type for representing email messages. It's built on top of RFC standards (RFC 2045, RFC 2046, RFC 5322) and provides a clean, type-safe API for creating emails.

## Features

- Type-safe email construction
- RFC-compliant MIME multipart bodies
- Multiple recipient kinds (To, CC, BCC)
- Text, HTML and multipart (text + HTML) bodies
- Custom headers as `RFC_5322.Header` values
- Built on RFC 2045, RFC 2046 and RFC 5322
- `Codable` in the separate `Email Foundation Integration` product

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/swift-standards/swift-email-standard", branch: "main")
]
```

Add the products to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Email Standard", package: "swift-email-standard"),
        .product(name: "Email Foundation Integration", package: "swift-email-standard")
    ]
)
```

## Usage

### Simple HTML Email

```swift
import Email_Standard
import EmailAddress_Standard
import RFC_5322

let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Welcome!",
    html: "<h1>Welcome to our service!</h1>",
    date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200)
)
```

### Plain Text Email

```swift
let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Hello",
    text: "Hello, World!",
    date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200)
)
```

### Email with Text and HTML Alternatives

```swift
let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Newsletter",
    text: "Plain text version of newsletter",
    html: "<h1>HTML version</h1><p>Newsletter content...</p>",
    date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200)
)
```

### Email with Multiple Recipients

```swift
let email = try Email(
    to: [
        try EmailAddress("user1@example.com"),
        try EmailAddress("user2@example.com")
    ],
    from: try EmailAddress("sender@example.com"),
    cc: [try EmailAddress("manager@example.com")],
    bcc: [try EmailAddress("archive@example.com")],
    date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200),
    subject: "Team Update",
    body: .html("<h1>Important Update</h1>")
)
```

### Email with Custom Headers

```swift
let email = try Email(
    to: [EmailAddress("recipient@example.com")],
    from: EmailAddress("sender@example.com"),
    subject: "Tracked Email",
    html: "<h1>Hello!</h1>",
    date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200),
    additionalHeaders: [
        .init(
            name: .init(__unchecked: (), rawValue: "X-Campaign-ID"),
            value: try .init("newsletter-2024")
        ),
        .init(name: .xMailer, value: try .init("MyApp 1.0"))
    ]
)
```

### Custom Multipart Messages

```swift
import RFC_2046

let multipart = try RFC_2046.Multipart.alternative(
    textContent: "Plain text version",
    htmlContent: "<h1>HTML version</h1>"
)

let email = try Email(
    to: [try EmailAddress("recipient@example.com")],
    from: try EmailAddress("sender@example.com"),
    date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200),
    subject: "Custom Message",
    body: .multipart(multipart)
)
```

### Accessing Email Properties

```swift
let headers = email.allHeaders

print(email.from.address)
print(email.to.map(\.address))
print(email.subject)
```

### The RFC 5322 Message

The wire form is an `RFC_5322.Message`; rendering it to bytes or text is the
job of the RFC 5322 coder.

```swift
import Binary
import RFC_5322_Coder

let message = try RFC_5322.Message(from: email)
let eml = String(message)
```

## Type Overview

### `Email`

The main email message type.

```swift
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

    public var allHeaders: [RFC_5322.Header]
}
```

### `Email.Body`

Email body content.

```swift
public enum Body: Hashable, Sendable {
    case text([Byte], charset: RFC_2045.Charset)
    case html([Byte], charset: RFC_2045.Charset)
    case multipart(RFC_2046.Multipart)

    public var contentType: RFC_2045.ContentType
    public var transferEncoding: RFC_2045.ContentTransferEncoding?
}
```

## Email Provider Integration

This type is designed to be provider-agnostic. Use it with email services like:

### Mailgun

```swift
extension Mailgun.Client {
    func send(_ email: Email) async throws {
        try await messages.send(RFC_5322.Message(from: email))
    }
}
```

### SendGrid, AWS SES, etc.

Similar extension patterns can be used with any email provider API.

## RFC Standards

This package builds on these RFC standards:

- **RFC 2045** - MIME Part 1: Format of Internet Message Bodies (Content-Type, Content-Transfer-Encoding)
- **RFC 2046** - MIME Part 2: Media Types (multipart/alternative, multipart/mixed)
- **RFC 5322** - Internet Message Format (message structure, headers, date and time)

## Requirements

- Swift 6.4+
- macOS 27+, iOS 27+, tvOS 27+, watchOS 27+

## Related Packages

- [swift-emailaddress-standard](https://github.com/swift-standards/swift-emailaddress-standard) - Email address validation and RFC compliance
- [swift-rfc-2045](https://github.com/swift-ietf/swift-rfc-2045) - MIME fundamentals
- [swift-rfc-2046](https://github.com/swift-ietf/swift-rfc-2046) - MIME multipart support
- [swift-subscriptions](https://github.com/coenttb/swift-subscriptions) - Subscription management with RFC 2369/8058 headers

## License

Licensed under Apache 2.0.

## Contributing

Contributions welcome! Please ensure:
- All tests pass
- Code follows existing style
- Type safety and RFC compliance maintained
