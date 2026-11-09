import Byte
import Email_Standard
import RFC_2045
import Testing

extension Email.Body {
    @Suite struct Encoding {
        @Suite struct Unit {
            @Test
            func `ASCII text declares 7bit`() {
                let body: Email.Body = .text("Hello, World!")

                #expect(body.transferEncoding == .sevenBit)
            }

            @Test
            func `UTF-8 text outside ASCII declares 8bit`() {
                let body: Email.Body = .text("Grüße")

                #expect(body.transferEncoding == .eightBit)
            }

            @Test
            func `ASCII HTML declares 7bit`() {
                let body: Email.Body = .html("<p>Hello</p>")

                #expect(body.transferEncoding == .sevenBit)
            }

            @Test
            func `UTF-8 HTML outside ASCII declares 8bit`() {
                let body: Email.Body = .html("<p>日本語</p>")

                #expect(body.transferEncoding == .eightBit)
            }
        }
    }
}
