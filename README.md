# Hasher

Used to sign correspondence and invoices

## Invoice source string

The HMAC source string for an invoice uses the following format:

    {date}:{client}:{project}:{price}:{counter}

That is:

 *  `date`: The invoice date in YYYYMMDD format
 *  `client`: Simple colloquial client name
 *  `project`: Simple colloquial project name
 *  `price`: The price, rounded to integer, excluding VAT
 *  `counter`: An unpadded 0-index counter digit to allow uniqueness

For example:

    20131004:Foo:Bar:1337:0