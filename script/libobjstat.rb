#!/usr/bin/ruby
require "libxmldb"
require "libiofile"

class ObjStat < XmlDb
  def initialize(doc)
    super(doc,'//status')
    @obj=doc.property['id']
    @f=IoFile.new(@obj)
    begin
      @stat=@f.load_json
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
    @f.save_json(@stat)
  end

  protected
  def get_fieldset
    str=String.new
    each_node {|e| #element(split and concat)
      f=@field[e.attr['ref']] || return
      case e.name
      when 'binary'
        str << (f.to_i >> e.attr['bit'].to_i & 1).to_s
      when 'float'
        if n=e.attr['decimal']
          n=n.to_i
          f=f[0..-n-1]+'.'+f[-n..-1]
        end
        str << e.format(f)
      when 'int'
        if e.attr['signed']
          f=[f.to_i].pack('S').unpack('s').first
        end
        str << e.format(f)
      else
        str << f
      end
    }
    return str
  end

  def get_stat
    stat=Hash.new
    each_node {|c| # var
      set=Hash.new
      c.add_attr(set)
      val=String.new
      c.node_with_name('fields') {|d|
        val=d.get_fieldset
        set['val']=val
      }
      @v.msg("#{c.attr['id']}=[#{val}]",1)
      c.symbol(val,set)
      set.delete('id')
      id="#{@obj}:#{c.attr['id']}"
      stat[id]=set
    }
    stat
  end

  def symbol(val,set)
    node_with_name('symbol') {|d|
      case d.attr['type']
      when 'min_base'
        @v.msg("Compare by Minimum Base for [#{val}]",1)
        d.each_node {|e|
          base=e.text
          @v.msg("Greater than [#{base}]?",1)
          next if base.to_f > val.to_f
          e.add_attr(set)
          break
        }
      when 'max_base'
        @v.msg("Compare by Maximum Base for [#{val}]",1)
        d.each_node {|e|
          base=e.text
          @v.msg("Less than [#{base}]?",1)
          next if base.to_f < val.to_f
          e.add_attr(set)
          break
        }
      else
        d.node_with_text(val) {|e| e.add_attr(set)}
      end
    }
  end

end
