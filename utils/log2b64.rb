#!/usr/bin/ruby
abort "Usage: log2b64 [logfiles]" if ARGV.size < 1
ARGV.each{|fname|
  /_v([0-9]).log/ =~ fname
  ver=$1.to_i
  open(fname){|fd|
    fd.each{|l|
      next if l.to_s.empty?
      tm,id,str=l.split("\t")
      if /^#/ !~ id
        ary=id.split(":")
        if /snd|rcv/ =~ ary[0]
          ary.unshift("##{ver}")
        elsif /[0-9]+/ =~ ary[1]
          ary[0],ary[1]="##{ary[1]}",ary[0]
        end
        id=ary * ':'
      end
      next unless str
      str=[eval(str)].pack("m").split("\n") * ''
      puts [tm,id,str].join("\t")
    }
  }
}
