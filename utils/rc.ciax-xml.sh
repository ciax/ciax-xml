#!/bin/bash --rcfile
# Required packages: ruby1.9.1 libxml-ruby1.9.1 libxml2-utils apache2 socat libxml-xpath-perl
addenv(){
    name=$1;shift
    list=$(IFS=: eval echo \$$name)
    if [ "$list" ] ; then
        for j; do
            for i in $list;do
                [ "$j" = "$i" ] && break 2
            done
            eval "export $name=$j:\$$name"
        done
    else
        eval "export $name=${*// /:}"
    fi
}

# Local functions
umask 022
shopt -s nullglob
export LANG="C"
addenv PATH "$HOME/bin" "$HOME/lib"
addenv RUBYLIB "$HOME/ciax-xml/script"
addenv XMLPATH "$HOME/ciax-xml"

#Alias
alias chkxml=check-xml
alias devsim=devsim-sql
alias jv=json-view
alias jlv=json-logview
alias jlp=json-logpick
alias mkhtm=make-html
alias msv=marshal-view
alias logj=sqlog-json
alias vc=view-ctrl
