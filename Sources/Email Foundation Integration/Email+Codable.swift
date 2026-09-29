public import Email_Standard
import EmailAddress_Foundation_Integration
import EmailAddress_Standard
import RFC_5322
import RFC_5322_Foundation_Integration

extension Email: Encodable, Decodable {

    private enum CodingKeys: String, CodingKey {
        case to, from, replyTo, cc, bcc, date, subject, body, additionalHeaders
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(
            to: container.decode([EmailAddress].self, forKey: .to),
            from: container.decode(EmailAddress.self, forKey: .from),
            replyTo: container.decodeIfPresent(EmailAddress.self, forKey: .replyTo),
            cc: container.decodeIfPresent([EmailAddress].self, forKey: .cc),
            bcc: container.decodeIfPresent([EmailAddress].self, forKey: .bcc),
            date: container.decode(RFC_5322.DateTime.self, forKey: .date),
            subject: container.decode(String.self, forKey: .subject),
            body: container.decode(Email.Body.self, forKey: .body),
            additionalHeaders: container.decode([RFC_5322.Header].self, forKey: .additionalHeaders)
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
