#!/usr/bin/ruby
require 'libverbose'
class Stat < Hash
  def initialize(hash={})
    @v=Verbose.new("stat",6)
    update(hash)
  end

  def to_h
    Hash[self]
  end

  def subst(str)
    return str unless /\$\{/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
      # output csv if array
      str=str.gsub(/\$\{(.+)\}/) {
        ary=[*get($1)].map!{|i| eval(i)}
        @v.abort("No value for subst [#{$1}]") if ary.empty?
        ary.join(',')
      }
      str
    ensure
      @v.msg(-1){"Substitute to [#{str}]"}
    end
  end

  # For multiple dimention (content should be numerical)
  def get(key) # ${key1:key2:idx} => hash[key1][key2][idx]
    @v.abort("No Key") unless key
    vname=[]
    key.split(':').inject(self){|h,i|
      begin
        i=eval(i) if Array === h
      rescue SyntaxError
        @v.abort("#{i} is not number")
      end
      vname << i
      @v.msg{"Type[#{h.class}] Name[#{i}]"}
      @v.msg{"Content[#{h[i]}]"}
      h[i]||@v.warn("No such Value [#{vname.join(':')}]")
    }
  end

  def set(key,val)
    get(key).replace(subst(val).to_s)
    self
  end
end
