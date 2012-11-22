#!/usr/bin/ruby
require 'libmsg'
require 'libupdate'
require 'libvar'

module Field
  class Var < Var
    extend Msg::Ver
    # @< (upd_proc)
    def initialize
      Var.init_ver(self,6)
      super('field')
    end

    # Substitute str by Field data
    # - str format: ${key}
    # - output csv if array
    def subst(str)
      return str unless /\$\{/ === str
        Var.msg(1){"Substitute from [#{str}]"}
        begin
          str=str.gsub(/\$\{(.+)\}/) {
            ary=[*get($1)].map!{|i| eval(i)}
            Msg.abort("No value for subst [#{$1}]") if ary.empty?
            ary.join(',')
          }
          str
        ensure
          Var.msg(-1){"Substitute to [#{str}]"}
        end
    end

    # First key is taken as is (key:x:y) or ..
    # Get value for key with multiple dimention
    # - index should be numerical or formula
    # - ${key:idx1:idx2} => hash[key][idx1][idx2]
    def get(key)
      Msg.abort("No Key") unless key
      return super if self['val'].key?(key)
      vname=[]
      data=key.split(':').inject(self['val']){|h,i|
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
        Var.msg{"Type[#{h.class}] Name[#{i}]"}
        Var.msg{"Content[#{h[i]}]"}
        h[i] || Msg.warn("No such Value [#{vname.join(':')}] in 'val'")
      }
      Msg.warn("Short Index [#{vname.join(':')}]") unless Comparable === data
      data
    end

    # Set value with mixed key
    def set(key,val)
      unless self['val'].key?(key.split(':').first)
        Msg.par_err("No such Key[#{key}] in 'val'")
      end
      if p=get(key)
        conv=subst(val).to_s
        case p
        when Array
          p.replace(conv.split(','))
        when String
          p.replace(conv)
        end
      else
        Msg.par_err("Index is out of range")
      end
      set_time
      self
    end

    def ext_save
      super
      extend Save
      self
    end
  end

  module Save
    # Saving data of specified keys with tag
    # @<< (upd_proc)
    def savekey(keylist,tag=nil)
      Msg.com_err("No File") unless @base
      hash={}
      keylist.each{|k|
        if self['val'].key?(k)
          hash[k]=get(k)
        else
          Msg.warn("No such Key [#{k}]")
        end
      }
      if hash.empty?
        Msg.par_err("No Keys")
      else
        tag||=(taglist.max{|a,b| a.to_i <=> b.to_i}.to_i+1)
        Msg.msg("Status Saving for [#{tag}]")
        save({'val'=>hash},tag)
      end
      self
    end
  end
end

if __FILE__ == $0
  f=Field::Var.new
  puts f.update({"a"=>[["0"],"1"]})
  if s=ARGV.shift
    k,v=s.split('=')
    if v
      puts f.set(k,v)
    else
      puts f.get(s)
    end
  end
  exit
end
