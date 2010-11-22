#!/usr/bin/ruby
require "optparse"
require "rexml/document"
include REXML

# //xpath@attr -> //xpath/attr.text()
abort "Usage: a2e (-r) [xpath] [attr] < xml" if ARGV.size < 2

xpath=ARGV.shift
if /-r/ === xpath
  xpath=ARGV.shift
  attr=ARGV.shift
  doc=Document.new(gets(nil))
  doc.each_element(xpath) {|e|
    val=''
    e.each_element("./#{attr}"){|e1| val=e1.text }
    e.add_attribute(attr,val)
    e.delete_element("./#{attr}")
  }
else
  attr=ARGV.shift
  doc=Document.new(gets(nil))
  doc.each_element(xpath) {|e|
    str=e.attributes[attr] || next
    e.delete_attribute(attr)
    e.add_element(attr).text=str
  }
end
puts doc
