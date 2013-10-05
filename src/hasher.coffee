#!/usr/bin/env coffee

cp = require 'child_process'
crypto = require 'crypto'
fs = require 'fs'
__ = require 'async'


ALGORITHM = 'sha256'
KEYFORMATEXP = /^-+BEGIN .+-+\n(?:(?:[a-zA-Z\-]+: .*\n)+\n)?((?:[A-Za-z0-9+/=]+\n)+)-+END .+-+\n?$/
SSHPATH = "#{process.env.HOME}/.ssh"

ERRORCODES =
	1: "Invalid options; please provide either a key phrase or a private key file path."
	2: "Failed to retrieve Keychain pass phrase."
	3: "Failed to decrypt key file."
	4: "Failed to parse decrypted key file."
	5: "Failed to compute hash."


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
		if not (argv.k? or argv.f?)?
			pass 1
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
					pass 2
				else
					opensslCommand = "openssl rsa -passin stdin -in #{keyPath}"
					opensslProcess = cp.exec opensslCommand, (err, key) ->
						if err?
							pass 3
						else if not (match = KEYFORMATEXP.exec key.toString 'utf8')?
							pass 4
						else
							#TODO: Extract actual key from binary storage format?
							pass null, new Buffer (match[1].replace /\n/g, ""), 'base64'
					opensslProcess.stdin.write password

	## Generate the hash
	(keyBuffer, pass) ->
		try
			pass null, do ((crypto
				.createHmac ALGORITHM, keyBuffer)
				.update argv._[0], 'utf8')
				.digest
		catch
			pass 5

], (err, hash) ->
	if err?
		console.error ERRORCODES[err] or "Failed; unknown error."
		process.exit err
	else
		console.log hash.toString 'hex'