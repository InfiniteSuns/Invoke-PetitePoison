# Invoke-PetitePoison #

A tool to match 'user:hash' files to 'hash:pass' files, creating a 'user:pass' file.

## What it's for ##

Imagine you have a long list of users and their hashes, and a hashcat potfile of craked hashes. Now you can create yourself a nice file consisting of only users with their cracked passwords.

## Usage ##

Note that this thing is extremely poorly written and slow AF. However, I tried to support Linux Powershell and V2. Test it.

The script is expecting a 'user:hash' and 'hash:pass' as -uh and -hp arguments. Optionally you can set a name for a resulting 'user:pass' file as -up argument:
- ```-UserHash is a path to 'user:hash' file (i.e. C:\UserHashPath.txt)```
- ```-HashPass is a path to 'hash:pass' file (i.e. C:\HashPassPath.txt)```
- ```-UserPass is a path to 'user:pass' file  file (i.e. C:\UserPassPath.txt)```
