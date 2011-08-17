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
begin
  open(file){|f|
    output=JSON.load(f.gets(nil))
  } if test(?r,file)
  str=STDIN.gets(nil) || raise
  input=JSON.load(str)
rescue
  abort
end
output=merge(input,output)
open(file,'w'){|f|
  f.puts(JSON.dump(output))
}


