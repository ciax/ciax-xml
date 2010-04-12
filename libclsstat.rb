#!/usr/bin/ruby
require "libcls"
TopNode='//status'
class ClsStat < Cls
  public
  def clsstat(fields)
    @var=fields
    @res=Hash.new
    putText
    return @res
  end

  protected
  def get_fieldset
    str=String.new
    each do |e| #element(split and concat)
      f=@var[e['ref']] || return
      case e.name
      when 'binary'
        str << (f.to_i >> e['bit'].to_i & 1).to_s
      when 'float'
        e.attr?('decimal') do |n|
          n=n.to_i
          f=f[0..-n-1]+'.'+f[-n..-1]
        end
        str << e.translate(f)
      when 'int'
        e.attr?('signed') do 
          f=[f.to_i].pack('S').unpack('s').first
        end
        str << e.translate(f)
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
      @v.msg("#{c['msg']}=[#{val}]")
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

end
