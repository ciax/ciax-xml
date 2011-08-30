#!/usr/bin/ruby
require 'json'
require 'libverbose'
require 'libmodio'

class Field < Hash
  include ModIo
  def initialize(id=nil)
    @v=Verbose.new("stat",5)
    @type="field_#{id}" if id
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
      @v.check(h[i]){"No such Value [#{vname.join(':')}]"}
    }
  end

  def set(key,val)
    get(key).replace(subst(val).to_s)
    self
  end
end
#!/usr/bin/ruby
require 'libverbose'
require 'libfield'

class IoField < Field

end
