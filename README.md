# swift-email-standard

Use this package when you compose an email message and need it as an RFC 5322 message you can render or hand to a mail transport. Start from `Email`, then turn it into a message with `RFC_5322.Message.init(from:)`. If you only need to parse or validate addresses, use `EmailAddress` from swift-emailaddress-standard. If you need full control over every header, build an `RFC_5322.Message` from swift-rfc-5322 directly. For `Codable`, add the `Email Foundation Integration` product.

## Laws

- Text and HTML bodies default to UTF-8. Their content type is `text/plain` or `text/html` with that charset, and their transfer encoding is always declared as 7bit. The bytes are passed through as given and are never transfer-encoded.
- A text and HTML email becomes a `multipart/alternative` body with the plain text part first and the HTML part second. `RFC_2046.Multipart.alternative(textContent:htmlContent:)` and `RFC_2046.Multipart.mixed(parts:)` pick a new random boundary on every call.
- `RFC_5322.Message.init(from:)` generates a new random Message-ID on every conversion, using the domain of the sender's address. It also adds the body's Content-Type and Content-Transfer-Encoding headers.
- With `Email Foundation Integration`, a body encodes with a `type` of `text`, `html` or `multipart`. Text and HTML content encodes as an array of byte values with its `charset`, not as a string.
