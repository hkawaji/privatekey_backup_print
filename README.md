# Privatekey print

This is a utility to print GnuPG private key for very long term backup
(on a printed material).

Secret keys (incl. primary and sub keys) are exported as a HTML file
including armored form, base16 (human readable), and QR code (of base64).
As far as you have a way to read some of the above, you should
be able to restore. You can keep this in a safe place in a form
of printed material (that is, paper), in addition to digital media (such
as CD-R, USB flash memory).

Note that the (paired) public keys are required to restore,
they are assumed to be available somewhere else such as public
keyservers or your contacts. You have to make sure the pubic keys
will be available when you restore.

Requirements (for encode ~ backup):
* bash
* GnuPG
* base64 (coreutils)
* paperkey (http://www.jabberwocky.com/software/paperkey/)
* libqrencode (https://fukuchi.org/works/qrencode/)

Requirements (for decode ~ restore)
* GnuPG
* base64 (coreutils)
* paperkey (http://www.jabberwocky.com/software/paperkey/)
* zbar (http://zbar.sourceforge.net/)

The basic idea came from this post:
https://gist.github.com/joostrijneveld/59ab61faa21910c8434c


