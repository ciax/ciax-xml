#!/usr/bin/ruby
require 'libmsg'
require 'json'
#Extened Hash
module CIAX
  # show_iv = Show Instance Variable
  module ViewStruct
    include Msg
    def view_struct(data,title=nil,ind=0,show_iv=false)
      str=''
      col=4
      id=data.object_id
      if title
        case title
        when Numeric
          title="[#{title}](#{id})"
        else
          title=title.inspect
          title+="(#{id})" if Enumerable === data
        end
        str << color("%-6s" % title,5,ind)+" :\n"
        ind+=1
      else
        str << "#\n"
      end
      iv={}
      data.instance_variables.each{|n|
        iv[n]=data.instance_variable_get(n) unless n == :object_ids
      } if show_iv
      _show(str,iv,ind,col,title,show_iv)
      _show(str,data,ind,col,title,show_iv)
    end

    private
    def _show(str,data,ind,col,title,show_iv)
      if Enumerable === data
        if (@object_ids||=[]).include?(data.object_id)
          return str.chomp + " #{data.class}(Loop)\n"
        else
          @object_ids << data.object_id
        end
      end
      case data
      when Array
        return str if _mixed?(str,data,data,data.size.times,ind,show_iv)
        return _only_ary(str,data,ind,col) if data.size > col
      when Hash
        return str if _mixed?(str,data,data.values,data.keys,ind,show_iv)
        return _only_hash(str,data,ind,col,title) if data.size > 2
      end
      str.chomp + " #{data.inspect}\n"
    end

    def _mixed?(str,data,vary,idx,ind,show_iv)
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << view_struct(data.fetch(i),i,ind,show_iv)
        }
      end
    end

    def _only_ary(str,data,ind,col)
      str << indent(ind)+"["
      line=[]
      data.each_slice(col){|a|
        line << a.map{|v| v.inspect}.join(",")
      }
      str << line.join(",\n "+indent(ind))+"]\n"
    end

    def _only_hash(str,data,ind,col,title)
      data.keys.each_slice(title ? 2 : 1){|a|
        str << indent(ind)+a.map{|k|
          color("%-8s" % k.inspect,3)+(": %-10s" % data.fetch(k).inspect)
        }.join("\t")+"\n"
      }
      str
    end
  end

  module Enumx
    include ViewStruct
    def self.extended(obj)
      raise("Not Enumerable") unless obj.is_a? Enumerable
    end

    def to_s
      view_struct(self)
    end

    def to_j
      case self
      when Array
        JSON.dump(to_a)
      when Hash
        JSON.dump(to_hash)
      end
    end

    # Show branch (omit lower tree of Hash/Array with sym key)
    def path(ary=[])
      enum=ary.inject(self){|prev,a|
        if /@/ === a
          prev.instance_variable_get(a)
        else
          case prev
          when Array
            prev[a.to_i]
          when Hash
            prev[a.to_sym]||prev[a.to_s]
          end
        end
      }||Msg.abort("No such key")
      branch=enum.dup
      if Hash === branch
        branch.each{|k,v|
          branch[k]=v.class.to_s if Enumerable === v
        }
      end
      branch.instance_variables.each{|n|
        v=branch.instance_variable_get(n)
        branch.instance_variable_set(n,v.class.to_s) if Enumerable === v
      }
      view_struct(branch)
    end

    def deep_copy
      Marshal.load(Marshal.dump(self))
    end

    # Freeze one level deepth or more
    def deep_freeze
      rec_proc(self){|i|
        i.freeze
      }
      self
    end

    # Merge self to ope
    def deep_update(ope,depth=nil)
      rec_merge(ope,self,depth)
      self
    end

    def read(json_str=nil)
      deep_update(j2h(json_str))
    end

    private
    def j2h(json_str=nil)
      JSON.load(json_str||gets(nil)||Msg.abort("No data in file(#{ARGV})"))
    end

    # r(operand) will be merged to w (w is changed)
    def rec_merge(r,w,d)
      d-=1 if d
      each_idx(r,w){|i,cls|
        w=cls.new unless cls === w
        if d && d < 1
          w[i]=r[i]
        else
          w[i]=rec_merge(r[i],w[i],d)
        end
      }
    end

    def rec_proc(db)
      each_idx(db){|i|
        rec_proc(db[i]){|d| yield d}
      }
      yield db
    end

    def each_idx(ope,res=nil)
      case ope
      when Hash
        ope.each_key{|k| yield k,Hash}
        res||ope.dup
      when Array
        ope.each_index{|i| yield i,Array}
        res||ope.dup
      when String
        ope.dup
      else
        ope
      end
    end
  end

  class Hashx < Hash
    include Enumx
  end

  class Arrayx < Array
    include Enumx
  end
end
