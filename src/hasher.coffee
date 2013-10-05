#!/usr/bin/env coffee

cp = require 'child_process'
crypto = require 'crypto'
asn1 = require 'asn1'
fs = require 'fs'
__ = require 'async'


ALGORITHM = 'sha256'
KEYFORMATEXP = /^-+BEGIN .+-+\n(?:(?:[a-zA-Z\-]+: .*\n)+\n)?((?:[A-Za-z0-9+/=]+\n)+)-+END .+-+\n?$/
SSHPATH = "#{process.env.HOME}/.ssh"

ERRORCODES =
	0x01: "Invalid options; please provide either a key phrase or a private key file path."
	0x02: "Failed to retrieve Keychain pass phrase."
	0x03: "Failed to decrypt key file."
	0x04: "Failed to parse decrypted key file."
	0x05: "Failed to compute hash."


argv = (((require 'optimist')
	.usage "Usage: $0 [-f KEYFILE -k KEYPHRASE] STRING")
	.demand 1)
	.options
		'k':
			alias: 'key'
			describe: 'a private key file path'
		'f':
			alias: 'file'
			describe: 'a key phrase string'
	.argv

__.waterfall [
	## Check the options (must enter either key phrase or key file path)
	(pass) ->
		if not (argv.k? or argv.f?)
			pass 0x01
		else
			do pass

	## Retrieve the key (either pass the phrase immediately, or load and decrypt the key file)
	(pass) ->
		if (keyPhrase = argv.k)?
			pass null, new Buffer keyPhrase, 'utf8'
		else
			keyPath = argv.f
			securityCommand = "security find-generic-password -wl \"SSH: #{keyPath}\""
			cp.exec securityCommand, (err, password) ->
				if err?
					pass 0x02
				else
					opensslCommand = "openssl rsa -passin stdin -in #{keyPath}"
					opensslProcess = cp.exec opensslCommand, (err, key) ->
						if err?
							pass 0x03
						else if not (match = KEYFORMATEXP.exec key.toString 'utf8')?
							console.error "Parsing err: unknown format."
							pass 0x04
						else
							keyData = new Buffer (match[1].replace /\n/g, ""), 'base64'
							readPrivateExponent keyData, (err, key) ->
								if err
									console.error "Parsing err: code 0x#{err.toString 16}."
									pass 0x04
								else
									pass null, key
					opensslProcess.stdin.write password

	## Generate the hash
	(keyBuffer, pass) ->
		try
			pass null, do ((crypto
				.createHmac ALGORITHM, keyBuffer)
				.update argv._[0], 'utf8')
				.digest
		catch
			pass 0x05

], (err, hash) ->
	if err?
		console.error ERRORCODES[err] or "Failed; unknown error."
		process.exit err
	else
		console.log hash.toString 'hex'


#-- Helper functions

readPrivateExponent = (data, callback) ->
	reader = new asn1.BerReader data
	__.waterfall [
		## Read the sequence and assert that it spans almost all the data
		(pass) ->
			if not 0x30 is do reader.readSequence
				pass 0x01
			else if not reader.length > 0.95 * data.length
				pass 0x02
			else
				do pass
		
		## Read the version and assert that it is 0
		(pass) ->
			if not 0x02 is do reader.readSequence
				pass 0x03
			else if not 0x00 is do reader.readByte
				pass 0x04
			else
				do pass
		
		## Read the modulus and assert that it is 0-leading
		(pass) ->
			if not 0x02 is do reader.readSequence
				pass 0x05
			else if not 0x00 is do reader.peek
				pass 0x06
			else
				reader._offset += reader.length
				do pass
		
		## Read the public exponent
		(pass) ->
			if not 0x02 is do reader.readSequence
				pass 0x07
			else if reader.length isnt 3
				pass 0x08
			else
				reader._offset += 3
				do pass

		## Read an pass on the private exponent
		(pass) ->
			if not 0x02 is do reader.readSequence
				pass 0x09
			else
				pass null, data[reader.offset...(reader.offset + reader.length)]
	], (err, result) ->
		if err?
			callback err
		else
			callback null, result