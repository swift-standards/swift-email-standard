import EmailAddress_Standard
import RFC_4648
import RFC_5322

extension Email {

    public enum ConversionError: Swift.Error, Sendable {

        case address(EmailAddress.Error)

        case header(RFC_5322.Header.Value.Error)

        case message(RFC_5322.Message.Error)
    }
}

extension RFC_5322.Message {

    public init(from email: Email) throws(Email.ConversionError) {

        let from: RFC_5322.EmailAddress
        let to: [RFC_5322.EmailAddress]
        let cc: [RFC_5322.EmailAddress]?
        let bcc: [RFC_5322.EmailAddress]?
        let replyTo: RFC_5322.EmailAddress?

        do {
            from = try RFC_5322.EmailAddress(email.from)
            to = try email.to.map {
                (addr: EmailAddress) throws(EmailAddress.Error) -> RFC_5322.EmailAddress in
                try RFC_5322.EmailAddress(addr)
            }

            cc = try email.cc.map {
                (ccList: [EmailAddress]) throws(EmailAddress.Error) -> [RFC_5322.EmailAddress] in
                try ccList.map {
                    (addr: EmailAddress) throws(EmailAddress.Error) -> RFC_5322.EmailAddress in
                    try RFC_5322.EmailAddress(addr)
                }
            }

            bcc = try email.bcc.map {
                (bccList: [EmailAddress]) throws(EmailAddress.Error) -> [RFC_5322.EmailAddress] in
                try bccList.map {
                    (addr: EmailAddress) throws(EmailAddress.Error) -> RFC_5322.EmailAddress in
                    try RFC_5322.EmailAddress(addr)
                }
            }

            replyTo = try email.replyTo.map {
                (addr: EmailAddress) throws(EmailAddress.Error) -> RFC_5322.EmailAddress in
                try RFC_5322.EmailAddress(addr)
            }
        } catch {
            throw .address(error)
        }

        let randomBytes = (0..<16).map { _ in Byte(UInt8.random(in: 0...255)) }
        let hexBytes: [ASCII.Code] = RFC_4648.Hex.encode(randomBytes, uppercase: false)
        let uniqueId = String(decoding: hexBytes, as: UTF8.self)

        let domain = from.domain
        let messageId = RFC_5322.Message.ID(uniqueId: uniqueId, domain: domain)

        let bodyData = email.body.data

        var additionalHeaders = email.additionalHeaders.filter { $0.name != .messageId }

        do {
            let contentTypeValue = try RFC_5322.Header.Value(
                ascii: [Byte](email.body.contentType.description.utf8)
            )
            additionalHeaders.append(
                .init(name: .contentType, value: contentTypeValue)
            )
            if let encoding = email.body.transferEncoding {
                let encodingValue = try RFC_5322.Header.Value(
                    ascii: [Byte](encoding.description.utf8)
                )
                additionalHeaders.append(
                    .init(name: .contentTransferEncoding, value: encodingValue)
                )
            }
        } catch {
            throw .header(error)
        }

        do {
            try self.init(
                from: from,
                to: to,
                cc: cc,
                bcc: bcc,
                replyTo: replyTo,
                date: email.date,
                subject: email.subject,
                messageId: messageId,
                body: Array(bodyData),
                additionalHeaders: additionalHeaders
            )
        } catch {
            throw .message(error)
        }
    }
}
