#!/usr/bin/ruby
module ModConv
  def keyconv(reg,str) # Key with index
    str.gsub(/({)?([^}{]+)(})?/){
      pre,main,suf=$1,$2,$3
      pre.to_s+main.split(':').map{|e|
        conv=e.gsub(/\$([#{reg}]+)/){ yield $1 }
        (conv == e || /\$/ === conv) ? e : eval(conv).to_s
      }.join(':')+suf.to_s
    }
  end
end
