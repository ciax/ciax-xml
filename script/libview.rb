#!/usr/bin/ruby
require 'libmsg'
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
          title << "(#{id})" if Enumerable === data
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
end
