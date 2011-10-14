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
      warn "No status at ExHash::update_j()"
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
      b= b.is_a?(Hash) ? b : {}
      a.keys.each{|i| b[i]=rec_merge(a[i],b[i])}
    when Array
      b= b.is_a?(Array) ? b : []
      a.size.times{|i| b[i]=rec_merge(a[i],b[i])}
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
      vary=data
      idx=data.size.times
      if vary.any?{|v| v.kind_of?(Enumerable)}
        idx.each{|i|
          str << view_struct(data[i],i,indent)
        }
        return str
      elsif  data.size > 11
        vary.each_slice(11){|a|
          str << "  " * indent + "#{a.inspect}\n"
        }
        return str
      end
    when Hash
      vary=data.values
      idx=data.keys
      if vary.any?{|v| v.kind_of?(Enumerable)} || data.size > 4
        idx.each{|i|
          str << view_struct(data[i],i,indent)
        }
        return str
      end
    end
    str.chomp + " #{data.inspect}\n"
  end
end
