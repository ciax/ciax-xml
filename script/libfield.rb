#!/usr/bin/ruby
require 'libmsg'
require 'libiofile'
require 'libupdate'
require 'libvar'

class Field < Var
  def initialize
    super('field')
  end

  # Substitute str by Field data
  # - str format: ${key}
  # - output csv if array
  def subst(str)
    return str unless /\$\{/ === str
    @v.msg(1){"Substitute from [#{str}]"}
    begin
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

  # First key is taken as is (key:x:y) or ..
  # Get value for key with multiple dimention
  # - index should be numerical or formula
  # - ${key:idx1:idx2} => hash[key][idx1][idx2]
  def get(key)
    Msg.abort("No Key") unless key
    return super if @val.key?(key)
    vname=[]
    data=key.split(':').inject(@val){|h,i|
      case h
      when Array
        begin
          i=eval(i)
        rescue SyntaxError,NoMethodError
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
    Msg.warn("Short Index [#{vname.join(':')}]") unless Comparable === data
    data
  end

  # Set value with mixed key
  def set(key,val)
    if p=get(key)
      p.replace(subst(val).to_s)
    else
      @val[key]=val
    end
    self.time=Msg::now
    self
  end
end

module Field::IoFile
  include IoFile
  # Saving data of specified keys with tag
  def savekey(keylist,tag=nil)
    Msg.err("No File") unless @base
    hash={}
    keylist.each{|k|
      if @val.key?(k)
        hash[k]=get(k)
      else
        Msg.warn("No such Key [#{k}]")
      end
    }
    if hash.empty?
      Msg.err("No Keys")
    else
      tag||=(taglist.max{|a,b| a.to_i <=> b.to_i}.to_i+1)
      Msg.msg("Status Saving for [#{tag}]")
      save({'val'=>hash},tag)
    end
    self
  end
end

module Field::SqLog
  def init(id,ver)
    @sql=SqLog::Logging.new('field',id,ver,@val)
    self
  end

  def save(data=nil,tag=nil)
    super
    @sql.save
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
