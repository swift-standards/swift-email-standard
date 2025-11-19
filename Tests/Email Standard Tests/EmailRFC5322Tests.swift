//
//  EmailRFC5322Tests.swift
//  swift-email-standard
//
//  Created by Coen ten Thije Boonkkamp on 12/11/2025.
//

import EmailAddress_Standard
import RFC_5322
import Testing

@testable import Email_Standard

@Suite
struct `Email to RFC 5322 Message Conversion` {

    @Test
    func `Convert simple text email to RFC 5322 Message`() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Test Email",
            body: "Hello, World!"  // ExpressibleByStringLiteral
        )

        let message = try RFC_5322.Message(from: email)

        #expect(message.from.address == "sender@example.com")
        #expect(message.to.count == 1)
        #expect(message.to[0].address == "recipient@example.com")
        #expect(message.subject == "Test Email")
        #expect(message.bodyString == "Hello, World!")

        let rendered = message.render()
        #expect(rendered.contains("From: sender@example.com"))
        #expect(rendered.contains("To: recipient@example.com"))
        #expect(rendered.contains("Subject: Test Email"))
        #expect(rendered.contains("Hello, World!"))
    }

    @Test
    func `Convert HTML email to RFC 5322 Message`() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "HTML Test",
            body: .html("<h1>Hello, World!</h1>")
        )

        let message = try RFC_5322.Message(from: email)

        #expect(message.bodyString?.contains("<h1>Hello, World!</h1>") == true)

        let rendered = message.render()
        #expect(rendered.contains("Content-Type: text/html"))
        #expect(rendered.contains("<h1>Hello, World!</h1>"))
    }

    @Test
    func `Convert multipart email to RFC 5322 Message`() throws {
        let multipart = try RFC_2046.Multipart.alternative(
            textContent: "Plain text version",
            htmlContent: "<p>HTML version</p>"
        )

        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Multipart Test",
            body: .multipart(multipart)
        )

        let message = try RFC_5322.Message(from: email)

        let rendered = message.render()
        #expect(rendered.contains("Content-Type: multipart/alternative"))
        #expect(rendered.contains("Plain text version"))
        #expect(rendered.contains("<p>HTML version</p>"))
    }

    @Test
    func `Convert email with CC and Reply-To`() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            replyTo: EmailAddress("reply@example.com"),
            cc: [EmailAddress("cc@example.com")],
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Test with CC",
            body: "Test body"
        )

        let message = try RFC_5322.Message(from: email)

        #expect(message.replyTo?.address == "reply@example.com")
        #expect(message.cc?.count == 1)
        #expect(message.cc?[0].address == "cc@example.com")

        let rendered = message.render()
        #expect(rendered.contains("Reply-To: reply@example.com"))
        #expect(rendered.contains("Cc: cc@example.com"))
    }

    @Test
    func `Convert email with custom headers`() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Test",
            body: "Test",
            additionalHeaders: [
                .init(name: "X-Custom-Header", value: "custom-value"),
                .init(name: "X-Priority", value: "1"),
            ]
        )

        let message = try RFC_5322.Message(from: email)

        let rendered = message.render()
        #expect(rendered.contains("X-Custom-Header: custom-value"))
        #expect(rendered.contains("X-Priority: 1"))
    }

    @Test
    func `Message-ID is generated if not provided`() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Test",
            body: "Test"
        )

        let message = try RFC_5322.Message(from: email)

        #expect(message.messageId.hasPrefix("<"))
        #expect(message.messageId.hasSuffix("@example.com>"))
        #expect(message.messageId.contains("@"))
    }

    @Test
    func `Can write message to .eml file`() throws {
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            date: RFC_5322.DateTime(secondsSinceEpoch: 1609459200),
            subject: "Test Email",
            body: "Hello, World!"
        )

        let message = try RFC_5322.Message(from: email)
        let emlContent = message.render()

        // Verify .eml format
        #expect(emlContent.contains("From: "))
        #expect(emlContent.contains("To: "))
        #expect(emlContent.contains("Subject: "))
        #expect(emlContent.contains("Date: "))
        #expect(emlContent.contains("Message-ID: "))
        #expect(emlContent.contains("\r\n\r\n"))  // Headers/body separator
    }
}
