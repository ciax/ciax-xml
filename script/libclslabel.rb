#!/usr/bin/ruby
require "libxmldoc"
require "liblabel"
require "libverbose"

class ClsLabel < Label
  def initialize(cls,id)
    super()
    @v=Verbose.new("Label")
    init_db(XmlDoc.new('cdb',cls),'id')
    @v.msg{"using[#{cls}] for class"}
    begin
      @odb=init_db(XmlDoc.new('odb',id),'ref')
      @v.msg{"using[#{id}] for object"}
    rescue SelectID
      @v.msg{"No [#{id}] for object"}
    end
  end

  private
  def init_db(doc,key)
    rep=Repeat.new
    rep.each(doc['status']){|e|
      sym=e['label'] || next
      id=rep.format(e[key])
      self[id]={'label'=>rep.format(sym)}
      self[id]['group']=rep.format(e['group']) if e['group']
    }
  end
end
