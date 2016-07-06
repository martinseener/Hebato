# Hebato - Hetzner Backup Tool

Hebato is a simple Bash Script for automating client-side encrypted backups on Hetzner's Backup Space or Storage Boxes using SSHFS and EncFS.

Build Status: [![Build Status](https://travis-ci.org/martinseener/Hebato.svg)](https://travis-ci.org/martinseener/Hebato)

## Why SSHFS and EncFS?

There are 2 simple reasons: While using SSHFS we can use tools like rsync/rdiff-backup (with --no-hard-links option!) to backup files
which would be a pain to use with plain sftp/scp or ftp and because SSHFS uses a secure transport channel by default and mounts the path as a normal directory.

EncFS is our client-side data encryption layer. After we mount the Backup Space via SSHFS, we "double-mount" this path to another path
using EncFS which then en- and decrypts data between the SSHFS mount path and the EncFS mount path "on-the-fly". You can read and write data
into the EncFS mount path and dont have to care about data security or transport security (which is a bonus now and not necessarily needed anymore!).

## How can i use it?

I'm glad you asked that. It's damn easy! Just copy the hebato.sh script into your /root folder (or a folder beneath. i like using /root/.scripts for that).
Now get into the script and change the parameters like your Hetzners Username and the mount paths you want to use. You don't even have to care about the EncFS
encryption key. The script will handle that automatically for you without exposing your super secret key anywhere (check the sources!).

What you need to do anyways is enabling the ability for your root user to login to the Backup- or Storage-Space just with a SSH keypair. Check this [tutorial](http://wiki.hetzner.de/index.php/Backup_Space_SSH_Keys/en) on how to do that. It will work for Storage-Boxes like it does for Backup-Boxes. Hebato will probably handle that in the future as well.

### Where can i put my backup scripts or commands?

Search for `## START` and `## END` in the hebato.sh source. Between those two you can put your stuff. As an example (and because iam using this script as it is in production)
there are 3 pre-defined backups made. The first two is [iRedmail's](http://www.iredmail.org/wiki/index.php?title=IRedMail/FAQ/Backup) backup scripts for LDAP and MySQL and the third
is rdiff-backup to backup the email files itself. This is easy because iRedmail uses the maildir format, so you can read and restore the emails later without special tools!

As a bonus the LDAP and MySQL backups are cleaned up whereas backups older than 3 months are deleted (who really need those?). With rdiff-backup this step is not necessary since
it backups files incrementally. If you have 2 new mails (files) since the last backup, only those 2 files are being added to the backup itself.

## How to trigger a regular backup?

Even easier. That's a perfect job for cron.

1. Run `crontab -e` as root
2. Add this line: `0 3 * * * /bin/bash /root/.scripts/hebato.sh`

That's it. This line will run Hebato every morning at 3 am on 7 days a week, 365 days a year!

## Are there more information on how this tool works?

Maybe there will be more documentation here later but in the meantime just be brave and take a look under the hood. It's open source and documented in-line!
I'll consider adding this tool in a plugin-version for my larger backup tool which handles much more than this. Stay tuned!

## Would you like to know more?

I made this small script for my very own personal backup project but since there is little information or even tools for this special backup scenario i wanted to open source
all this for everyone's use. There is also a blog post with more detailed steps available. [Check it out](https://www.sysorchestra.com/2014/09/01/hetzner-backup-service-with-sshfs-for-iredmail-on-debianubuntu/)

## Copyright and License

This little tool was made by Martin Seener (c) 2014-2016
Feel free to contribute! Use feature branches for new stuff or bugfixes before you submit them to me!

Released under the MIT License. License file is attached in this repository.