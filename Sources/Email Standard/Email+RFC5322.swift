public import EmailAddress_Standard
public import RFC_5322
import ASCII
import Byte
import RFC_2045
import RFC_2045_Coder
import RFC_2046_Coder
import RFC_4648

extension Email {

    public enum ConversionError: Swift.Error, Sendable {

        case address(EmailAddress.Error)

        case header(RFC_5322.Header.Value.Error)

        case message(RFC_5322.Message.Error)
    }
}

extension RFC_5322.Message {

    public init(from email: Email) throws(Email.ConversionError) {

        let from: RFC_5322.Mailbox
        let to: [RFC_5322.Mailbox]
        let cc: [RFC_5322.Mailbox]?
        let bcc: [RFC_5322.Mailbox]?
        let replyTo: RFC_5322.Mailbox?

        do {
            from = try RFC_5322.Mailbox(email.from)
            to = try email.to.map {
                (addr: EmailAddress) throws(EmailAddress.Error) -> RFC_5322.Mailbox in
                try RFC_5322.Mailbox(addr)
            }

            cc = try email.cc.map {
                (ccList: [EmailAddress]) throws(EmailAddress.Error) -> [RFC_5322.Mailbox] in
                try ccList.map {
                    (addr: EmailAddress) throws(EmailAddress.Error) -> RFC_5322.Mailbox in
                    try RFC_5322.Mailbox(addr)
                }
            }

            bcc = try email.bcc.map {
                (bccList: [EmailAddress]) throws(EmailAddress.Error) -> [RFC_5322.Mailbox] in
                try bccList.map {
                    (addr: EmailAddress) throws(EmailAddress.Error) -> RFC_5322.Mailbox in
                    try RFC_5322.Mailbox(addr)
                }
            }

            replyTo = try email.replyTo.map {
                (addr: EmailAddress) throws(EmailAddress.Error) -> RFC_5322.Mailbox in
                try RFC_5322.Mailbox(addr)
            }
        } catch {
            throw .address(error)
        }

        let randomBytes = (0..<16).map { _ in Byte(bitPattern: UInt8.random(in: 0...255)) }
        let hexBytes: [ASCII.Code] = RFC_4648.Base16.encode(randomBytes, uppercase: false)
        let uniqueId = String(decoding: hexBytes.lazy.map(\.underlying), as: UTF8.self)

        let domain = from.domain
        let messageId = RFC_5322.Message.ID(uniqueId: uniqueId, domain: domain)

        let bodyData = email.body.bytes

        var additionalHeaders = email.additionalHeaders.filter { $0.name != .messageId }

        do {
            let contentTypeValue = try RFC_5322.Header.Value(
                email.body.contentType.description
            )
            additionalHeaders.append(
                .init(name: .contentType, value: contentTypeValue)
            )
            if let encoding = email.body.transferEncoding {
                let encodingValue = try RFC_5322.Header.Value(encoding.description)
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
                body: bodyData,
                additionalHeaders: additionalHeaders
            )
        } catch {
            throw .message(error)
        }
    }
}

extension Email.Body {

    fileprivate var bytes: [Byte] {
        switch self {
        case .text(let bytes, _), .html(let bytes, _):
            return bytes

        case .multipart(let multipart):
            return [Byte](multipart)
        }
    }
}
