# Hebato Changelog

Hebato is a simple Bash Script for automating client-side encrypted backups on Hetzner's Backup Space using SSHFS and EncFS.
The Code can be found at [https://github.com/martinseener/Hebato](https://github.com/martinseener/Hebato)

## v1.0
- added Hetzner Storage Box support
- removed OpenSSL dependency
- better security by using Kernels urandom to generate EncFS Key
- enhanced logging to syslog and stdout (disabled/enabled/debug/interactive)
- added Shellcheck (Syntax/Bug-Check) and Bashate (Linting) via Travis-CI
- added dependency and mount path checks
- changed license from GPLv2 to MIT
## v0.1
- Intitial Version