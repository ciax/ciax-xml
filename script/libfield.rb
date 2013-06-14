#!/usr/bin/ruby
require 'libupdate'
require 'libvar'

module CIAX
  module Field
    class Var < Var
      def initialize
        @ver_color=6
        super('field')
        ext_upd
      end

      # Substitute str by Field data
      # - str format: ${key}
      # - output csv if array
      def subst(str)
        return str unless /\$\{/ === str
        verbose("Field","Substitute from [#{str}]")
        enclose{
          str=str.gsub(/\$\{(.+)\}/) {
            ary=[*get($1)].map!{|i| eval(i)}
            Msg.abort("No value for subst [#{$1}]") if ary.empty?
            ary.join(',')
          }
        }
        verbose("Field","Substitute to [#{str}]")
        str
      end

      # First key is taken as is (key:x:y) or ..
      # Get value for key with multiple dimention
      # - index should be numerical or formula
      # - ${key:idx1:idx2} => hash[key][idx1][idx2]
      def get(key)
        verbose("Field","Getting[#{key}]")
        Msg.abort("Nill Key") unless key
        return self['val'][key] if self['val'].key?(key)
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
          verbose("Field","Type[#{h.class}] Name[#{i}]")
          verbose("Field","Content[#{h[i]}]")
          h[i] || warning("Field","No such Value [#{vname.join(':')}] in 'val'")
        }
        unless Comparable === data
          warning("Field","Short Index [#{vname.join(':')}]")
          data=nil
        end
        verbose("Field","Get[#{key}]=[#{data}]")
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
        self['time']=UnixTime.now
        upd
      end

      def ext_save
        super
        extend Save
        self
      end
    end

    module Save
      # Saving data of specified keys with tag
      def savekey(keylist,tag=nil)
        Msg.com_err("No File") unless @base
        hash={}
        keylist.each{|k|
          if self['val'].key?(k)
            hash[k]=get(k)
          else
            warning("Field/Save","No such Key [#{k}]")
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
end
