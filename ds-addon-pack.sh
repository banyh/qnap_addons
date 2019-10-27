#!/bin/sh

ERR_IS_NOT_FOLDER="is not a folder."
ERR_IS_NOT_EXISTS="is not a file."
ERR_RSA_PRI_FORMAT="RSA private key is not allowed."
ERR_RSA_PUB_FORMAT="RSA public key is not allowed."
ERR_RSA_KEY_LENGTH="RSA key is not 1024 bit."

assert(){
    echo ""
    echo "$1"
    echo ""
    exit 1
}

is_rsa_pri_key(){
    echo "KEY" | /usr/bin/openssl rsautl -inkey "$1" -encrypt > /dev/null 2>&1
    [ "$?" -eq "0" ] || assert "$ERR_RSA_PRI_FORMAT"
}

is_rsa_pub_key(){
    echo "KEY" | /usr/bin/openssl rsautl -inkey "$1" -pubin -encrypt > /dev/null 2>&1
    [ "$?" -eq "0" ] || assert "$ERR_RSA_PUB_FORMAT"
}

is_1024_bit(){
   local key_length=`/usr/bin/openssl rsa -in "$1" -text -noout 2>/dev/null | sed -nr 's/^Private-Key: .([0-9]+) bit.$/\1/p'`
   [ "$key_length" -eq "1024" ] || assert "$ERR_RSA_KEY_LENGTH"
}

pack(){
    local pri_key="$1"
    local pub_key="$2"
    local pub_key_path=`dirname $pub_key`
    local pub_key_file=`basename $pub_key`
    local addon_path="$3"
    local addon_pack=`pwd`
    local addon_name=`basename "$addon_path"`
    local addon_json="$addon_path/addon.json"

    [ -d "$addon_path" ] || assert "$addon_path $ERR_IS_NOT_FOLDER"
    [ -f "$addon_json" ] || assert "$addon_json $ERR_IS_NOT_EXISTS"

    local addon_build="$addon_path/addon.build"
    local addon_version=`sed -nr 's/^.*version.*:[ \t\n]*([0-9]+).*$/\1/p' "$addon_json"`

    local major=$(($addon_version/100))
    local minor=$(($addon_version%100))
    local build=`date +"%Y%m%d"`
    local addon_version="${major}.${minor}.${build}"

    local addon_filename="$4"
    if [ "${addon_filename}" = "" ]; then
        addon_filename="$addon_pack/${addon_name}_${addon_version}.addon"
    fi

    echo "$build" > "$addon_build"

    tar --exclude="addon.key" --exclude="CVS" -cf "$addon_filename" -C "$addon_path" `ls -1 "$addon_path"`
    cd "$pub_key_path" >/dev/null 2>&1
    tar --append --file="$addon_filename" --transform="s/$pub_key_file/addon.key/" "$pub_key_file"
    cd - >/dev/null 2>&1

    local addon_sha1=`cat "$addon_filename" | /usr/bin/openssl sha1 | sed 's/^.* //'`
    echo "$addon_sha1" | /usr/bin/openssl rsautl -inkey "$pri_key" -sign >> "$addon_filename"
    echo "$addon_filename SHA1: $addon_sha1"
}

usage(){
    echo ""
    echo "Usage: $0 <private.pem> <public.pem> <addon folder> [addon file]"
    echo ""
    echo "private.pem: /usr/bin/openssl genrsa -out private.pem 1024"
    echo "public.pem: /usr/bin/openssl rsa -in private.pem -out public.pem -outform PEM -pubout"
    echo ""
    exit 1
}

[ "$#" -lt 3 ] && usage

is_rsa_pri_key "$1"
is_1024_bit "$1"
is_rsa_pub_key "$2"

pack ${@}
