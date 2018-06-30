#!/bin/bash 


# default param
BYTE=512
OUTDIR=./tmp


########################
# subroutine
########################
function usage()
{
  cat <<EOF

Generate a HTML file to backup GnuPG secret keys (for printing on paper).

  $0 [-b BYTE(default:${BYTE})] [-o OUTDIR(default:${OUTDIR}) ]

Secret keys (incl. primary and sub keys) are exported as a HTML file
including armored form, base16 (human readable), and QR code (of base64),
so that a few of them could be recognizable in future.

Note that the public keys are required to restore the private key,
and it is assumed that the public keys are available somewhere else
such as public keyserver or your contacts. You have to make sure
the public key will be available.

Requirements (for encode ~ backup):
* GnuPG
* base64 (coreutils)
* paperkey (http://www.jabberwocky.com/software/paperkey/)
* libqrencode (https://fukuchi.org/works/qrencode/)

Requirements (for decode ~ restore)
* GnuPG
* base64 (coreutils)
* paperkey (http://www.jabberwocky.com/software/paperkey/)
* zbar (http://zbar.sourceforge.net/)


The basic idea came from the post below:
https://gist.github.com/joostrijneveld/59ab61faa21910c8434c

EOF
}


function print_for_restore()
{
  local outfile=$1
  cat <<EOF >> ${outfile}

<h3> restore the key </h3>

Note that public keys have to be available in the pubring.
(It is assumed that the public keys are available somewhere else
such as public keyserver or your contacts)

<pre>
# decode QR code
for X in IMG*.png
do
  zbarimg --raw \$X \
  | head -c -1 \
  > \$X.out
done

# import key to the specified pubring 
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

<h3> contents of the key (gpg --list-packets) </h3>
<pre>
EOF
  gpg --list-packets $k >> ${outfile}
  printf "\n</pre>\n\n" >> ${outfile}
}


function print_key_armor()
{
  local outfile=$1
  printf "\n\n<h3> key in armor</h3>\n<pre>\n" >> ${outfile}
  cat ${k}.armor >> ${outfile}
  printf "</pre>" >> ${outfile}
}


function print_key_base16()
{
  local outfile=$1
  printf "\n\n<h3> key in base16</h3>\n<pre>\n" >> ${outfile}
  cat $k | paperkey --output-type base16 >> ${outfile}
  printf "</pre>" >> ${outfile}
}


function print_key_qrcode()
{
  local outfile=$1

  printf "\n\n<h3> key in QR code</h3>\n<pre>\n" >> ${outfile}
  for X in ${OUTDIR}/*.png 
  do
    xbase=$(basename $X)
    printf "<h4>$xbase</h4><img src='$xbase' />\n" >> ${outfile}
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
  o) OUTDIR=${OPTARG};;
  *) usage;;
  esac
done

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
print_for_restore ${k}.html
print_key_content ${k}.html
print_key_armor ${k}.html
print_key_base16 ${k}.html
print_key_qrcode ${k}.html
printf "</body></html>\n" >> ${k}.html
