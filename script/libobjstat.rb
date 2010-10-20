#!/usr/bin/ruby
require "libxmldoc"
require "libmodxml"
require "libverbose"
require "librepeat"
require "libstatsym"

class ObjStat < Hash
  include ModXml
  attr_reader :stat

  def initialize(obj)
    @odb=XmlDoc.new('odb',obj)
  rescue RuntimeError
    abort $!.to_s
  else
    @stat={'time'=>{'label'=>'LAST UPDATE','type'=>'DATETIME'}}
    @v=Verbose.new("odb/#{obj}".upcase)
    @value,@group={},0
    @rep=Repeat.new
    @odb['comm'].each_element{|e|
      self[e.name]=e.text
    }
    @sym=StatSym.new(@v)
  end
  
  public
  def get_stat(value)
    return unless value
    @value.update(value)
    @odb['status'].each_element{|g| stat_group(g) }
    @stat['time']['val']=@value['time']
    @stat
  end

  private
  #Stat Methods
  def stat_group(e)
    case e.name
    when 'group'
      @group+=1
      e.each_element{|g| stat_group(g) }
    when 'title'
      get_var(e)
    when 'repeat'
      @rep.repeat(e){|d| stat_group(d) }
    end
  end

  def get_var(var) # //status/var
    st={'group' => @group }
    a=var.attributes
    ref=@rep.sub_index(a['ref'])
    st['title']=@rep.sub_index(var.text)
    st['val']=@value[ref]
    @v.msg{"STAT:GetStatus:#{ref}=[#{st['val']}]"}
    st.update(@sym.get_symbol(a['symbol'],st['val']))
    st.update(@sym.get_level(a['level'],st['val']))
    @stat[ref]=st
  end

end
