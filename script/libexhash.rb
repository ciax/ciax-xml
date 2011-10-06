#!/usr/bin/ruby
require 'json'
class ExHash < Hash
  def to_s
    view_struct(self)
  end

  def to_j
    JSON.dump(Hash[self])
  end

  def update_j(str)
    if str && !str.empty?
      deep_update(JSON.load(str))
    else
      warn "No status in File"
    end
    self
  end

  def deep_update(hash)
    rec_merge(hash,self)
    self
  end

  private
  def rec_merge(a,b)
    case a
    when Hash
      b||={}
      a.keys.each{|k|
        b[k]=rec_merge(a[k],b[k])
      }
    when Array
      b||=[]
      a.size.times{|i|
        b[i]=rec_merge(a[i],b[i])
      }
    else
      b=a||b
    end
    b
  end

  def view_struct(data,title=nil,indent=0)
    str=''
    if title
      case title
      when Numeric
        title="[#{title}]"
      else
        title=title.inspect
      end
      str << "  " * indent + ("%-4s :\n" % title)
      indent+=1
    end
    case data
    when Array
      unless data.all?{|v| v.kind_of?(Comparable)}
        data.each_with_index{|v,i|
          str << view_struct(v,i,indent)
        }
        return str
      end
    when Hash
      if data.values.any?{|v| ! v.kind_of?(Comparable)} || data.size > 4
        data.each{|k,v|
          str << view_struct(v,k,indent)
        }
        return str
      end
    end
    str.chomp + " #{data.inspect}\n"
  end
end
