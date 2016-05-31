#!/bin/bash
[ "$PROJ" = moircs ] && h=m || h=t
make-html ${h}ix gtr
make-html ${h}ft gc
make-html ${h}fp gmos ggv
make-html ${h}ma gm
make-html ${h}mc gabs
make-html ${h}ap -
