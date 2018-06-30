#!/bin/bash 


# default param
BYTE=512
OUTFILE=secret-key.html


########################
# subroutine
########################
function usage()
{
  cat <<EOF

Generate a HTML file to backup GnuPG secret keys (for printing on paper).

  $0 [-b BYTE(default:${BYTE})] [-o OUTDIR(default:${OUTDIR}) ]

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

EOF
}


function print_introduction()
{
  local outfile=$1
  cat <<EOF >> ${outfile}

<h2> Backup material of GnuPG private key </h2>

<p>
This HTML file is generated to backup GnuPG secret key, by using <q> $0 </q>.
It contains:
</p>

<ul>
<li> an armored form  (--armor)</li>
<li> base16 encode (human readable)</li>
<li> QR code (for scanning)</li>
</ul>

<p>
Secret keys (incl. primary and sub keys) are exported as a HTML file
including armored form, base16 (human readable), and QR code (of base64).
As far as you have a way to read some of the above, you should
be able to restore. You can keep this in a safe place in a form
of printed material (that is, paper), in addition to digital media (such
as CD-R, USB flash memory)
</p>

<p>
Note that the (paired) public keys are required to restore,
they are assumed to be available somewhere else such as public
keyservers or your contacts. You have to make sure the pubic keys
will be available when you restore.
</p>

<h3> How to restore the QR encoded keys </h3>

Firstly, you have to decode QR code with some way.
This is an example to do it by using zbar ( http://zbar.sourceforge.net/ )

<pre>
for X in IMG*.png
do
  zbarimg --raw \$X \
  | head -c -1 \
  > \$X.out
done
</pre>

Now it is ready to import like below. 
Please make sure the paired public key is available in your keyring.

<pre>
cat *.out \
| base64 -d \
| paperkey --pubring ~/.gnupg/pubring.gpg \
| gpg --import
</pre>

EOF
}


function print_key_content()
{
  local outfile=$1
  cat <<EOF >> ${outfile}

<h3> Contents of the key (gpg --list-packets) </h3>
<pre>
EOF
  gpg --list-packets $k >> ${outfile}
  printf "\n</pre>\n\n" >> ${outfile}
}


function print_key_armor()
{
  local outfile=$1
  printf "\n\n<h3> Keys in armor</h3>\n<pre>\n" >> ${outfile}
  cat ${k}.armor >> ${outfile}
  printf "</pre>" >> ${outfile}
}


function print_key_base16()
{
  local outfile=$1
  printf "\n\n<h3> Keys in base16</h3>\n<pre>\n" >> ${outfile}
  cat $k | paperkey --output-type base16 >> ${outfile}
  printf "</pre>" >> ${outfile}
}


function print_key_qrcode()
{
  local outfile=$1

  printf "\n\n<h3> Keys in QR code</h3>\n<pre>\n" >> ${outfile}
  for X in ${OUTDIR}/*.png 
  do
    img_data=$( base64 ${X} )
    printf "<h4>$xbase</h4><img src='data:image/png;base64,${img_data}' />\n" >> ${outfile}
  done

}

  
#####################
# main
#####################

# prep
while getopts b:o: opt
do
  case ${opt} in
  b) BYTE=${OPTARG};;
  o) OUTFILE=${OPTARG};;
  *) usage;;
  esac
done

OUTDIR=${OUTFILE}.tmp
mkdir -p $OUTDIR
k=${OUTDIR}/secret-key.gpg
rm -f ${k} ${k}.html

# export
gpg --export-secret-key --output ${k}
gpg --export-secret-key --armor --output ${k}.armor

# split the secret keys, and convert them
cat ${k} \
| paperkey --output-type raw \
| base64 \
| split -b $BYTE - ${k}.base64_

for X in ${k}.base64_*
do
  cat $X | qrencode --level=H -o $X.png
done

# generate a HTML file
printf "<html><body>\n" >> ${k}.html
print_introduction ${k}.html
print_key_content ${k}.html
print_key_armor ${k}.html
print_key_base16 ${k}.html
print_key_qrcode ${k}.html
printf "</body></html>\n" >> ${k}.html
chmod go-rwx ${k}.html

mv -f ${k}.html ${OUTFILE}
shred --remove ${k}.base64_*
shred --remove ${k}.armor
shred --remove ${k}
rmdir ${OUTDIR}


