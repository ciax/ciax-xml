#!/usr/bin/ruby
require 'libdatax'

module CIAX
  module Frm
    class Field < DataH
      attr_accessor :echo
      def initialize(init_struct={})
        super('field',init_struct)
        @cls_color=6
        @pfx_color=11
      end

      def set_db(db)
        super
        # Field Initialize
        if @data.empty?
          @db[:field].each{|id,val|
            @data[id]=val['val']||Arrayx.new.skeleton(val[:struct])
          }
        end
        self
      end

      # Substitute str by Field data
      # - str format: ${key}
      # - output csv if array
      def subst(str) # subst by field
        return str unless /\$\{/ === str
        enclose("Field","Substitute from [#{str}]","Substitute to [%s]"){
          str.gsub(/\$\{(.+)\}/) {
            ary=[*get($1)].map!{|i| eval(i)}
            Msg.abort("No value for subst [#{$1}]") if ary.empty?
            ary.join(',')
          }
        }
      end

      # First key is taken as is (key:x:y) or ..
      # Get value for key with multiple dimention
      # - index should be numerical or formula
      # - ${key:idx1:idx2} => hash[key][idx1][idx2]
      def get(key)
        verbose("Field","Getting[#{key}]")
        Msg.abort("Nill Key") unless key
        return @data[key] if @data.key?(key)
        vname=[]
        dat=key.split(':').inject(@data){|h,i|
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
          h[i] || alert("Field","No such Value [#{vname.join(':')}] in 'data'")
        }
        verbose("Field","Get[#{key}]=[#{dat}]")
        dat
      end

      # Put value with mixed key
      def put(key,val)
        akey=key.split(':')
        if @data.key?(akey.shift) && p=get(key)
          conv=subst(val).to_s
          verbose("Field","Put[#{key}]=[#{conv}]")
          case p
          when Array
            p.replace(conv.split(','))
          when String
            p.replace(eval(conv).to_s)
          end
        elsif akey.empty?
          @data[key]=val
        else
          Msg.par_err("Index is out of range")
        end
        verbose("Field","Evaluated[#{key}]=[#{@data[key]}]")
        self['time']=now_msec
        self
      ensure
        post_upd
      end
    end

    if __FILE__ == $0
      f=Field.new({"a"=>[["0"],"1"]})
      puts f.to_j
      if s=ARGV.shift
        k,v=s.split('=')
        if v
          puts f.put(k,v)
        else
          puts f.get(s)
        end
      end
      exit
    end
  end
end
