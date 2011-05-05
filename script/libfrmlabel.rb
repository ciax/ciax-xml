#!/usr/bin/ruby
require "libxmldoc"
require "liblabel"

class FrmLabel < Label
  def initialize(id)
    super()
    doc=XmlDoc.new('fdb',id)
    doc.find_each('rspframe','field[@label]'){|e|
      id=e['assign'] || next
      self[id]={'label'=>e['label']}
      self[id]['group']=e['group'] if e['group']
    }
  end
end
