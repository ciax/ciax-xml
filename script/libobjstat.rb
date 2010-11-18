#!/usr/bin/ruby
require "libxmldoc"
require "libmodxml"
require "libverbose"
require "librepeat"
require "libstatsym"

class ObjStat
  include ModXml
  def initialize(obj)
    @odb=XmlDoc.new('odb',obj)
  rescue RuntimeError
    abort $!.to_s
  else
    @stat={'time'=>{'label'=>'LAST UPDATE','type'=>'DATETIME'}}
    @v=Verbose.new("odb/#{obj}".upcase)
    @value,@group={},0
    @rep=Repeat.new
    @sym=StatSym.new(@v)
  end
  
  public
  def get_view(value)
    return unless value
    @value.update(value)
    @odb['status'].each{|g| stat_group(g) }
    @stat['time']['val']=@value['time']
    @stat
  end

  private
  #Stat Methods
  def stat_group(e)
    case e.name
    when 'group'
      @group+=1
      e.each{|e1| stat_group(e1) }
    when 'title'
      get_var(e)
    when 'repeat'
      @rep.repeat(e){
        e.each{|e1| stat_group(e1) }
      }
    end
  end

  def get_var(var) # //status/var
    st={'group' => @group }
    ref=@rep.subst(var['ref'])
    st['title']=@rep.subst(var.text)
    st['val']=@value[ref]
    @v.msg{"STAT:GetStatus:#{ref}=[#{st['val']}]"}
    st.update(@sym.get_symbol(var['symbol'],st['val']))
    st.update(@sym.get_level(var['level'],st['val']))
    @stat[ref]=st
  end

end
