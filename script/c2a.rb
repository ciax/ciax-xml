#!/usr/bin/ruby
require "optparse"
require "rexml/document"
include REXML

abort "Usage: a2c [xpath] [attr] < xml" if ARGV.size < 2

xpath=ARGV.shift
attr=ARGV.shift
doc=Document.new(gets(nil))
doc.each_element(xpath) {|e|
  str=e.elements[attr].text
  str=e.add_attribute(attr,str)
  e.delete_element(attr)
}
puts doc
