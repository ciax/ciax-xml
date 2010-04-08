dev=${1:-k3n}
sndfrm2 $dev getstat|visi && rspfrm2 $dev getstat < ~/.var/${dev}_getstat.bin
