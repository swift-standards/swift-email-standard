public import RFC_2046
import RFC_2045

extension RFC_2046.Multipart {

    public static func alternative(
        textContent: some StringProtocol,
        htmlContent: some StringProtocol
    ) throws(Error) -> Self {
        let parts: [RFC_2046.BodyPart] = [
            .init(contentType: .textPlainUTF8, text: textContent),
            .init(contentType: .textHTMLUTF8, text: htmlContent),
        ]
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
