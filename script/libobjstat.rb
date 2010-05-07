#!/usr/bin/ruby
require "libxmldb"
require "libmodfile"
class ObjStat < XmlDb
  include ModFile
  def initialize(doc)
    super(doc,'//status')
    begin
      @stat=load_stat(@property['id']) || raise
    rescue
      warn $!
      @stat=Hash.new
    end
  end

  attr_reader :stat,:field

  def objstat(fields)
    set_var!(fields,'field')
    @field=fields
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
        e.attr_with_key('decimal') do |n|
          n=n.to_i
          f=f[0..-n-1]+'.'+f[-n..-1]
        end
        str << e.format(f)
      when 'int'
        e.attr_with_key('signed') do 
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
      c.add_attr(set)
      val=String.new
      c.node_with_name('fields') do |d|
        val=d.get_fieldset
        set['val']=val
      end
      msg("#{c['id']}=[#{val}]")
      c.symbol(val,set)
      set.delete('id')
      @stat[c['id']]=set
    end
  end

  def symbol(val,set)
    node_with_name('symbol') do |d|
      case d['type']
      when 'min_base'
        msg "Compare by Minimum Base for [#{val}]"
        d.each_node do |e|
          base=e.text
          msg("Greater than [#{base}]?",1)
          next if base.to_f > val.to_f
          e.add_attr(set)
          break
        end
      when 'max_base'
        msg "Compare by Maximum Base for [#{val}]"
        d.each_node do |e|
          base=e.text
          msg("Less than [#{base}]?",1)
          next if base.to_f < val.to_f
          e.add_attr(set)
          break
        end
      else
        d.node_with_text(val) do |e|
          e.add_attr(set)
        end
      end
    end
  end

end


