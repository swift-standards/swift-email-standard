import RFC_6531
import Binary
import Byte
import Email_Standard
import EmailAddress_Standard
import RFC_5322
import RFC_5322_Coder
import Testing

@Suite
struct `README Verification` {

    @Test
    func `Example from README: Simple HTML Email`() throws {

        let email = try Email(
            to: [EmailAddress(rfc6531: try RFC_6531.Mailbox("recipient@example.com"))],
            from: EmailAddress(rfc6531: try RFC_6531.Mailbox("sender@example.com")),
            subject: "Welcome!",
            html: "<h1>Welcome to our service!</h1>",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200)
        )

        #expect(email.to.count == 1)
        #expect(email.from.address == "sender@example.com")
        #expect(email.subject == "Welcome!")
    }

    @Test
    func `Example from README: Plain Text Email`() throws {

        let email = try Email(
            to: [EmailAddress(rfc6531: try RFC_6531.Mailbox("recipient@example.com"))],
            from: EmailAddress(rfc6531: try RFC_6531.Mailbox("sender@example.com")),
            subject: "Hello",
            text: "Hello, World!",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200)
        )

        let message = try RFC_5322.Message(from: email)

        #expect(email.subject == "Hello")
        #expect(String(decoding: message.body, as: UTF8.self) == "Hello, World!")
    }

    @Test
    func `Example from README: Email with Text and HTML Alternatives`() throws {

        let email = try Email(
            to: [EmailAddress(rfc6531: try RFC_6531.Mailbox("recipient@example.com"))],
            from: EmailAddress(rfc6531: try RFC_6531.Mailbox("sender@example.com")),
            subject: "Newsletter",
            text: "Plain text version of newsletter",
            html: "<h1>HTML version</h1><p>Newsletter content...</p>",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200)
        )

        let message = try RFC_5322.Message(from: email)
        let rendered = String(message)

        #expect(email.subject == "Newsletter")
        #expect(rendered.contains("Content-Type: multipart/alternative"))
        #expect(rendered.contains("Plain text version of newsletter"))
        #expect(rendered.contains("<h1>HTML version</h1>"))
    }

    @Test
    func `Example from README: Email with Custom Headers`() throws {

        let email = try Email(
            to: [EmailAddress(rfc6531: try RFC_6531.Mailbox("recipient@example.com"))],
            from: EmailAddress(rfc6531: try RFC_6531.Mailbox("sender@example.com")),
            subject: "Tracked Email",
            html: "<h1>Hello!</h1>",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200),
            additionalHeaders: [
                .init(
                    name: .init(__unchecked: (), rawValue: "X-Campaign-ID"),
                    value: try .init("newsletter-2024")
                ),
                .init(
                    name: .xMailer,
                    value: try .init("MyApp 1.0")
                ),
            ]
        )

        #expect(
            email.additionalHeaders[.init(__unchecked: (), rawValue: "X-Campaign-ID")]
                == "newsletter-2024"
        )
        #expect(email.additionalHeaders[.xMailer] == "MyApp 1.0")
    }
}
