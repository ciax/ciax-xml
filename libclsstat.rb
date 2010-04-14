#!/usr/bin/ruby
require "libcls"
TopNode='//status'
class ClsStat < Cls
  public
  def clsstat(fields)
    @field=fields
    @stat=Hash.new
    get_stat
    return @stat
  end

  protected
  def get_fieldset
    str=String.new
    each_node do |e| #element(split and concat)
      f=@field[e['ref']] || return
      case e.name
      when 'binary'
        str << (f.to_i >> e['bit'].to_i & 1).to_s
      when 'float'
        e.attr?('decimal') do |n|
          n=n.to_i
          f=f[0..-n-1]+'.'+f[-n..-1]
        end
        str << e.format(f)
      when 'int'
        e.attr?('signed') do 
          f=[f.to_i].pack('S').unpack('s').first
        end
        str << e.format(f)
      else
        str << f
      end
    end
    return str
  end

  def get_stat
    str=String.new
    each_node do |c| # var
      set=Hash.new
      set.update(c.attr_to_hash)
      val=String.new
      c.node_with_name('fields') do |d|
        val=d.get_fieldset
        set['val']=val
      end
      @v.msg("#{c['id']}=[#{val}]")
      c.node_with_name('symbol') do |d|
        case d['type']
        when 'range'
          d.each_node do |e|
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
      set.delete('id')
      @stat[c['id']]=set
    end
  end

end

