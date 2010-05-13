#!/usr/bin/ruby
require "libxmldb"
require "libvarfile"

class ObjStat < XmlDb
  def initialize(doc)
    super(doc,'//status')
    @f=VarFile.new(@property['id'])
    begin
      @stat=@f.load_stat
    rescue
      warn $!
      @stat={'time'=>{'label'=>'LAST UPDATE','type'=>'DATETIME'}}
    end
  end

  attr_reader :stat,:field

  def objstat(fields)
    set_var!(fields,'field')
    @field=fields
    @stat.update(get_stat)
    @stat['time']['val']=Time.at(@field['time'].to_f)
    @f.save_stat(@stat)
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
    stat=Hash.new
    each_node do |c| # var
      set=Hash.new
      c.add_attr(set)
      val=String.new
      c.node_with_name('fields') do |d|
        val=d.get_fieldset
        set['val']=val
      end
      @v.msg("#{c['id']}=[#{val}]",1)
      c.symbol(val,set)
      set.delete('id')
      id="#{@property['id']}:#{c['id']}"
      stat[id]=set
    end
    stat
  end

  def symbol(val,set)
    node_with_name('symbol') do |d|
      case d['type']
      when 'min_base'
        @v.msg("Compare by Minimum Base for [#{val}]",1)
        d.each_node do |e|
          base=e.text
          @v.msg("Greater than [#{base}]?",1)
          next if base.to_f > val.to_f
          e.add_attr(set)
          break
        end
      when 'max_base'
        @v.msg("Compare by Maximum Base for [#{val}]",1)
        d.each_node do |e|
          base=e.text
          @v.msg("Less than [#{base}]?",1)
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
