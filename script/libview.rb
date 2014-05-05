#!/usr/bin/ruby
require 'libmsg'
module CIAX
  # show_iv = Show Instance Variable
  module ViewStruct
    include Msg
    def view_struct(show_iv=1)
      _recursive(self,nil,[],0,show_iv)
    end

    private
    def _recursive(data,title,object_ary,indent,show_iv)
      str=''
      column=4
      id=data.object_id
      if title
        case title
        when Numeric
          title="[#{title}]"
          str << color("%-6s" % title,6,indent)
        when /@/
          str << color("%-6s" % title.inspect,1,indent)
        else
          str << color("%-6s" % title.inspect,2,indent)
        end
        str << color("(#{id})",4) if Enumerable === data
        str << " :\n"
        indent+=1
      else
        str << "#\n"
      end
      iv={}
      data.instance_variables.each{|n|
        iv[n]=data.instance_variable_get(n) unless n == :object_ids
        show_iv-=1 # Show only top level of the instance variable
      } if show_iv > 0
      _show(str,iv,object_ary,indent,column,title,show_iv)
      _show(str,data,object_ary,indent,column,title,show_iv)
    end

    def _show(str,data,object_ary,indent,column,title,show_iv)
      if Enumerable === data
        if object_ary.include?(data.object_id)
          return str.chomp + " #{data.class}(Loop)\n"
        else
          object_ary << data.object_id
        end
      end
      case data
      when Array
        return str if _mixed?(str,data,data,data.size.times,object_ary,indent,show_iv)
        return _only_ary(str,data,indent,column) if data.size > column
      when Hash
        return str if _mixed?(str,data,data.values,data.keys,object_ary,indent,show_iv)
        return _only_hash(str,data,indent,title) if data.size > 2
      end
      str.chomp + " #{data.inspect}\n"
    end

    def _mixed?(str,data,vary,idx,object_ary,indent,show_iv)
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << _recursive(data.fetch(i),i,object_ary,indent,show_iv)
        }
      end
    end

    def _only_ary(str,data,indent,column)
      str << indent(indent)+"["
      line=[]
      data.each_slice(column){|a|
        line << a.map{|v| v.inspect}.join(",")
      }
      str << line.join(",\n "+indent(indent))+"]\n"
    end

    def _only_hash(str,data,indent,title)
      data.keys.each_slice(title ? 2 : 1){|a|
        str << indent(indent)+a.map{|k|
          color("%-8s" % k.inspect,3)+(": %-10s" % data.fetch(k).inspect)
        }.join("\t")+"\n"
      }
      str
    end
  end
end
