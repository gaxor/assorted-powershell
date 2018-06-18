# List of commands from Jessica Payne (@jepayneMSFT)

Import-Module ActiveDirectory

# Check for accounts that don't have password expiry set
# Non expiring passwords are bad. Especially if it's a regular unexpected user, might be IOC [indicator of compromise] then.
Get-ADUser -Filter 'useraccountcontrol -band 65536' -Properties useraccountcontrol | export-csv U-DONT_EXPIRE_PASSWORD.csv

# Check for accounts that have no password requirement
# I hope I don't have to explain why password not required is bad. :)
Get-ADUser -Filter 'useraccountcontrol -band 32' -Properties useraccountcontrol | export-csv U-PASSWD_NOTREQD.csv

# Accounts that have the password stored in a reversibly encrypted format
# Because storing your password in reversible encryption is really bad.
Get-ADUser -Filter 'useraccountcontrol -band 128' -Properties useraccountcontrol | export-csv U-ENCRYPTED_TEXT_PWD_ALLOWED.csv

# List users that are trusted for Kerberos delegation
# Because unconstrained Kerberos delegation means that random service account can make Kerberos tickets for EVERYONE! Yay!
Get-ADUser -Filter 'useraccountcontrol -band 524288' -Properties useraccountcontrol | export-csv U-TRUSTED_FOR_DELEGATION.csv

# List accounts that don't require pre-authentication
# Pre auth puts your time stamp encrypted into the request to help against attacks.
Get-ADUser -Filter 'useraccountcontrol -band 4194304' -Properties useraccountcontrol | export-csv U-DONT_REQUIRE_PREAUTH.csv

# List accounts that have credentials encrypted with DES
# Because DES = plaintext essentially.
Get-ADUser -Filter 'useraccountcontrol -band 2097152' -Properties useraccountcontrol | export-csv U-USE_DES_KEY_ONLY.csv