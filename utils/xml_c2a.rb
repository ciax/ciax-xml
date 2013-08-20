#!/usr/bin/ruby
# XML Child Element with Text to Attribute Converter
require "optparse"
require "rexml/document"
include REXML

abort "Usage: a2c [xpath] [child_elem(w/text)] < xml" if ARGV.size < 2

xpath=ARGV.shift
attr=ARGV.shift
doc=Document.new(gets(nil))
doc.each_element(xpath) {|e|
  c=e.elements[attr] || next
  e.add_attribute(attr,c.text)
  e.delete_element(attr)
}
puts doc
