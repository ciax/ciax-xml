#!/usr/bin/ruby
require "libxmldb"
require "libstat"
class ClsStat < XmlDb
  include Stat
  def initialize(doc)
    super(doc,'//status')
  end

  public
  def clsstat(fields)
    set_var!(fields,'field')
    @field=fields
    get_stat
    return @var
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
      @v.msg("#{c['id']}=[#{val}]")
      c.symbol(val,set)
      set.delete('id')
      @var[c['id']]=set
    end
  end

end
