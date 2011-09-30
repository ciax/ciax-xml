#!/usr/bin/ruby
require 'json'
require 'libmsg'
require 'libmodfile'

class Field < Hash
  include ModFile
  def initialize(id=nil)
    @v=Msg::Ver.new("field",6)
    if id
      @type="field_#{id}"
      self["id"]=id
    end
  end

  def subst(str)
    return str unless /\$\{/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # output csv if array
      str=str.gsub(/\$\{(.+)\}/) {
        ary=[*get($1)].map!{|i| eval(i)}
        Msg.abort("No value for subst [#{$1}]") if ary.empty?
        ary.join(',')
      }
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  # For multiple dimention (content should be numerical)
  def get(key) # ${key1:key2:idx} => hash[key1][key2][idx]
    Msg.abort("No Key") unless key
    vname=[]
    key.split(':').inject(self){|h,i|
      case h
      when Array
        begin
          i=eval(i)
        rescue SyntaxError
          Msg.abort("#{i} is not number")
        end
      when nil
        break
      end
      vname << i
      @v.msg{"Type[#{h.class}] Name[#{i}]"}
      @v.msg{"Content[#{h[i]}]"}
      h[i] || Msg.warn("No such Value [#{vname.join(':')}]")
    }
  end

  def set(key,val)
    get(key).replace(subst(val).to_s)
    self
  end
end

if __FILE__ == $0
  f=Field.new
  puts f.update({"a"=>[["0"],"1"]})
  if s=ARGV.shift
    k,v=s.split('=')
    if v
      puts f.set(k,v)
    else
      puts f.get(s)
    end
  end
end
