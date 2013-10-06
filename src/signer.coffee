#!/usr/bin/env coffee

cp = require 'child_process'
crypto = require 'crypto'
fs = require 'fs'
__ = require 'async'


ALGORITHM = 'sha256'
KEYFORMATEXP = /^-+BEGIN .+-+\n(?:(?:[a-zA-Z\-]+: .*\n)+\n)?((?:[A-Za-z0-9+/=]+\n)+)-+END .+-+\n?$/
SSHPATH = "#{process.env.HOME}/.ssh"

ERRORCODES =
	0x01: "Invalid options; please provide either a key phrase or a private key file path."
	0x02: "Failed to retrieve Keychain pass phrase."
	0x03: "Failed to create temporary file."
	0x04: "Failed to sign string with given key."
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

options = {}

__.waterfall [
	## Check the options (must enter either key phrase or key file path)
	(pass) ->
		if not ((options.keyPhrase = argv.k)? or (options.keyFilePath = argv.f)?)
			pass 0x01
		else
			pass null, new Buffer argv._[0] or '', 'utf8'

	## Retrieve the key (either pass the phrase immediately, or load and decrypt the key file)
	(stringBuffer, pass) ->
		if options.keyPhrase?
			pass null, stringBuffer, new Buffer options.keyPhrase, 'utf8'
		else
			__.waterfall [
				# Retrieve the private key file password from Keychain
				(pass) ->
					securityCommand = 
					cp.exec "
						security
						find-generic-password -w
						-l \"SSH: #{options.keyFilePath}\"
					", (err, keychainPassword) ->
						pass (if err? then 0x02 else null), keychainPassword
				
				## Create a temporary file containing the source string
				(keychainPassword, pass) ->
					cp.exec "
						mktemp
						-t 'signing'
					", encoding: 'utf8', (err, temporaryPath) ->
						if err?
							pass 0x03
						else
							temporaryPath = options.temporaryPath = do temporaryPath.trim
							fs.writeFile temporaryPath, stringBuffer, (err) ->
								pass null, temporaryPath, keychainPassword

				## Sign the temporary source sting file using the private key file
				(temporaryPath, keychainPassword, pass) ->
					cp.exec "
						openssl rsautl
						-sign
						-passin stdin
						-inkey #{options.keyFilePath}
						-in #{temporaryPath}
					", encoding: 'binary', (err, keyData) ->
						if err?
							console.error "[Signer] OpenSSL error:"
							console.error err
							pass 0x04
						else
							pass null, new Buffer keyData, 'binary'

					## Enter the password retrieved from Keychain
					.stdin.write new Buffer keychainPassword, 'utf8'

			], (err, keyBuffer) ->
				if (temporaryPath = options.temporaryPath)?
					## Remove the temporary file
					fs.unlink temporaryPath, (err) ->
						console.error "[Signer] Failed to remove temporary file: '#{temporaryPath}'" if err?

				if err?
					pass err
				else
					pass null, stringBuffer, keyBuffer

	## Generate the hash
	(stringBuffer, keyBuffer, pass) ->
		try
			pass null, keyBuffer, do ((crypto
				.createHmac ALGORITHM, keyBuffer)
				.update stringBuffer)
				.digest
		catch
			pass 0x05

], (err, keyBuffer, hashBuffer) ->
	if err?
		console.error "[Signer] Error:", err
	else
		output = hashBuffer.toString 'hex'
		if options.keyFilePath?
			output = "#{keyBuffer.toString 'base64'}\n\n#{output}"
		process.stdout.write output