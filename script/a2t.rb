#!/usr/bin/ruby
require "optparse"
require "rexml/document"
include REXML

abort "Usage: a2t [xpath] [attr] < xml" if ARGV.size < 2

xpath=ARGV.shift
attr=ARGV.shift
doc=Document.new(gets(nil))
doc.each_element(xpath) {|e|
  str=e.attributes[attr] || next
  e.delete_attribute(attr)
  e.text=str
}
puts doc
