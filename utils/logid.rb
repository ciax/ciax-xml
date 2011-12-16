#!/usr/bin/ruby
require 'optparse'

def filter(fname,output)
  type,id,sfx=fname.split('_')
  /v([0-9])\.log/ =~ sfx
  ver=$1.to_i
  open(fname){|fd|
    fd.each{|l|
      next if l.to_s.empty?
      tm,cid,str=l.split("\t")
      next unless str
      if /^#{id}/ !~ cid
        ary=cid.split(":")
        if /^#/ =~ ary[0]
          ary[0]=$'
        elsif /[0-9]+/ =~ ary[1]
          ary[0],ary[1]=ary[1],ary[0]
        elsif /snd|rcv/ =~ ary[0]
          ary.unshift(ver)
        end
        ary.unshift(id)
        cid=ary * ':'
      end
      output.puts [tm,cid,str].join("\t")
    }
  }
end

abort "Usage: logid (-w) [logfiles]" if ARGV.size < 1
opt=ARGV.getopts("w")

ARGV.each{|fname|
  if opt['w']
    bkup=fname+'~'
    File.rename(fname,bkup)
    open(fname,'w'){|output|
      filter(bkup,output)
    }
  else
    filter(fname,STDOUT)
  end
}
