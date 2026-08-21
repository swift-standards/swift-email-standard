import RFC_2045
import RFC_2046

extension RFC_2046.Multipart {

    public static func alternative(
        textContent: some StringProtocol,
        htmlContent: some StringProtocol
    ) throws(Error) -> Self {
        let parts: [RFC_2046.BodyPart]
        do {
            parts = [
                try .init(
                    contentType: .textPlainUTF8,
                    text: String(textContent)
                ),
                try .init(
                    contentType: .textHTMLUTF8,
                    text: String(htmlContent)
                ),
            ]
        } catch {

            throw .invalidBodyPart(error.description)
        }
        return try Self(
            subtype: .alternative,
            parts: parts,
            boundary: .random()
        )
    }

    public static func mixed(
        parts: [RFC_2046.BodyPart]
    ) throws(Error) -> Self {
        try Self(
            subtype: .mixed,
            parts: parts,
            boundary: .random()
        )
    }
}
