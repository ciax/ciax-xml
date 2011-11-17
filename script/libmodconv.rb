#!/usr/bin/ruby
module ModConv
  def keyconv(reg,str) # Key with index
    str.gsub(/(\$\{)?([^\}\{]+)(\})?/){
      $1.to_s+$2.split(':').map{|e|
        conv=e.gsub(/\$([#{reg}])/){ yield $1 }
        (conv == e || /\$/ === conv) ? e : eval(conv).to_s
      }.join(':')+$3.to_s
    }
  end
end
