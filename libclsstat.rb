#!/usr/bin/ruby
require "libcls"
TopNode='//status'
class ClsStat < Cls
  def get_fieldset
    str=String.new
    each do |e| #element(split and concat)
      f=@var[e['ref']] || return
      case e.name
      when 'binary'
        str << (f.to_i >> e['bit'].to_i & 1).to_s
      when 'float'
        x = e['factor'] || "1"
        c = e['offset'] || "0"
        fmt = e['format'] || "%f"
        val=(x.to_f * f.to_f + c.to_f).to_s
        str << fmt % val
      when 'int'
        val=e.tr_text(f)
        fmt = e['format'] || "%d"
        str << fmt % val.to_s
      else
        str << f
      end
    end
    return str
  end

  def putText
    str=String.new
    each do |c| # var
      set=Hash.new
      set.update(c.attr_to_hash)
      @prefix="VER:#{set['id']}"
      val=String.new
      c.node_with_name('fields') do |d|
        val=d.get_fieldset
        set['val']=val
      end
      msg "=[#{val}]"
      c.node_with_name('symbol') do |d|
        case d['type']
        when 'range'
          d.each do |e|
            min,max=e.text.split(':')
            next if max.to_f < val.to_f
            next if min.to_f > val.to_f
            set.update(e.attr_to_hash)
            break
          end
        else
          d.node_with_text(val) do |e|
            set.update(e.attr_to_hash)
          end
        end
      end
      px=(@n) ? "#{@n}:" : ''
      set.delete('id')
      @res[px + c['id']]=set
    end
  end
  
  def clsstat(fields)
    @var=fields
    @res=Hash.new
    putText
    return @res
  end
end



