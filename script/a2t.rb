#!/usr/bin/ruby
require "optparse"
require "rexml/document"
include REXML

# //xpath@attr <-> //xpath.text()
abort "Usage: a2t (-r) [xpath] [attr] < xml" if ARGV.size < 2

xpath=ARGV.shift
if /-r/ === xpath
  xpath=ARGV.shift
  attr=ARGV.shift || abort("No attr")
  doc=Document.new(gets(nil))
  doc.each_element(xpath) {|e|
    e.add_attribute(attr,e.text)
    e.text=nil
  }
else
  attr=ARGV.shift
  doc=Document.new(gets(nil))
  doc.each_element(xpath) {|e|
    str=e.attributes[attr] || next
    e.delete_attribute(attr)
    e.text=str
  }
end
puts doc
