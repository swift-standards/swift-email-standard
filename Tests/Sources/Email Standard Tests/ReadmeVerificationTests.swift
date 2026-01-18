import Testing

@testable import Email_Standard

@Suite
struct `README Verification` {

    @Test
    func `Example from README: Simple HTML Email`() throws {
        // From README line 36-44
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
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
        // From README line 49-56
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Hello",
            text: "Hello, World!",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200)
        )

        #expect(email.subject == "Hello")
        #expect(email.body.content.contains("Hello, World!"))
    }

    @Test
    func `Example from README: Email with Text and HTML Alternatives`() throws {
        // From README line 60-68
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Newsletter",
            text: "Plain text version of newsletter",
            html: "<h1>HTML version</h1><p>Newsletter content...</p>",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200)
        )

        #expect(email.subject == "Newsletter")
        #expect(email.body.content.contains("Plain text version"))
        #expect(email.body.content.contains("<h1>HTML version</h1>"))
    }

    @Test
    func `Example from README: Email with Custom Headers`() throws {
        // From README line 88-99
        let email = try Email(
            to: [EmailAddress("recipient@example.com")],
            from: EmailAddress("sender@example.com"),
            subject: "Tracked Email",
            html: "<h1>Hello!</h1>",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200),
            additionalHeaders: [
                .init(
                    name: .init(__unchecked: (), rawValue: "X-Campaign-ID"),
                    value: try .init(ascii: Array("newsletter-2024".utf8))
                ),
                .init(
                    name: .xMailer,
                    value: try .init(ascii: Array("MyApp 1.0".utf8))
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
