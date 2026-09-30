import RFC_6531
import Email_Foundation_Integration
import Email_Standard
import EmailAddress_Standard
import Foundation
import RFC_2046
import RFC_5322
import Testing

@Suite
struct `Email Codable` {

    @Test
    func `A text email survives a JSON round trip`() throws {
        let email = try Email(
            to: [EmailAddress(rfc6531: try RFC_6531.Mailbox("recipient@example.com"))],
            from: EmailAddress(rfc6531: try RFC_6531.Mailbox("sender@example.com")),
            subject: "Welcome!",
            text: "Hello, World!",
            date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200)
        )

        let encoded = try JSONEncoder().encode(email)
        let decoded = try JSONDecoder().decode(Email.self, from: encoded)

        #expect(decoded == email)
    }

    @Test
    func `A multipart email survives a JSON round trip`() throws {
        let multipart = try RFC_2046.Multipart.alternative(
            textContent: "Plain text version",
            htmlContent: "<p>HTML version</p>"
        )

        let email = try Email(
            to: [EmailAddress(rfc6531: try RFC_6531.Mailbox("recipient@example.com"))],
            from: EmailAddress(rfc6531: try RFC_6531.Mailbox("sender@example.com")),
            date: RFC_5322.DateTime(secondsSinceEpoch: 1_609_459_200),
            subject: "Newsletter",
            body: .multipart(multipart)
        )

        let encoded = try JSONEncoder().encode(email)
        let decoded = try JSONDecoder().decode(Email.self, from: encoded)

        #expect(decoded == email)
    }
}
