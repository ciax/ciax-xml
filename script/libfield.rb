#!/usr/bin/ruby
require 'libmsg'
require 'libiofile'

class Field < IoFile
  # pdoc array executed in upd()
  attr_reader :updlist
  def initialize(id=nil,host=nil)
    super('field',id,host)
    @updlist=[]
  end

  # Update Field
  def upd
    @updlist.each{|p| p.call }
    self
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

  # Get value for key with multiple dimention
  # - index should be numerical or formula
  # - ${key:idx1:idx2} => hash[key][idx1][idx2]
  def get(key)
    Msg.abort("No Key") unless key
    return self[key] if key?(key)
    vname=[]
    key.split(':').inject(self){|h,i|
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
  end

  # Set value with mixed key
  def set(key,val)
    get(key).replace(subst(val).to_s)
    self
  end

  # Loading data with tag
  def loadkey(tag=nil)
    Msg.err("No File Name")  unless @base
    fn=settag(tag)
    @v.msg{"Status Loading for [#{fn}]"}
    begin
      load
    rescue
      if tag
        raise UserError,list_stat
      else
        Msg.warn("----- No #{fn}")
      end
    end
    self
  end

  # Saving data of specified keys with tag
  def savekey(keylist,tag=nil)
    Msg.err("No File Name")  unless @base
    hash={}
    keylist.each{|k|
      if key?(k)
        hash[k]=self[k]
      else
        Msg.warn("No such Key [#{k}]")
      end
    }
    if hash.empty?
      Msg.warn("No Keys")
    else
      tag||=Time.now.strftime('%y%m%d-%H%M%S')
      fn=settag(tag)
      @v.msg{"Status Saving for [#{fn}]"}
      save(hash)
      mklink(fn,tag)
    end
    self
  end

  private
  def mklink(fname,tag)
    return unless tag
    sname="#{@base}_latest.json"
    File.unlink(sname) if File.exist?(sname)
    File.symlink(fname,sname)
    @v.msg{"Symboliclink to [#{sname}]"}
  end

  def list_stat
    list=[]
    Dir.glob("#{@base}_*.json"){|f|
      tag=f.slice(/#{@base}_(.+)\.json/,1)
      list << tag
    }
    "Tag=#{list}"
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
