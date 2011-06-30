#!/usr/bin/ruby
require "json"

def merge(a,b)
  case a
  when Hash
    b||={}
    a.each_key{|k|
      b[k]=merge(a[k],b[k])
    }
  when Array
    b||=[]
    a.each_index{|i|
      b[i]=merge(a[i],b[i])
    }
  else
    b=a||b
  end
  b
end
if STDIN.tty? || ! file=ARGV.shift
  abort "Usage: merging [status_file] < [json_data]\n#{$!}"
end
output={}
open(file){|f|
  output=JSON.load(f.gets(nil))
} if test(?r,file)
str=STDIN.gets(nil) || exit
input=JSON.load(str)
output=merge(input,output)
open(file,'w'){|f|
  f.puts(JSON.dump(output))
}


