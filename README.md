# Signer

Used to sign correspondence and invoices.

## Installation

Download and `cd` into the repository, and run:

    make install

## Usage

Using a key passed in through the options (will output an _HMAC_ signature):

    ./bin/signer -k "Super secret passphrase" "Some string to be signed"

Or, using a private key file (will output the _OpenSSL_ signature, a newline, and a nice and short _HMAC_ signature using the _OpenSSL_ signature as the key):

    ./bin/signer -f /path/to/private.key "Some string to be signed"


## Invoice source string

The to-be-signed source string for an invoice uses the following format:

    {date}:{client}:{project}:{amount}:{counter}

That is:

 *  `date`: The invoice date in YYYYMMDD format
 *  `client`: Simple colloquial client name
 *  `project`: Simple colloquial project name
 *  `amount`: The payment amount, rounded to integer, excluding VAT
 *  `counter`: An unpadded 0-index counter digit to allow uniqueness

For example:

    ./bin/signer -f /path/to/private.key "20131004:Foo:Bar:1337:0"