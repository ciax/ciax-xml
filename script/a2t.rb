#!/usr/bin/ruby
require "optparse"
require "rexml/document"
include REXML

if ARGV.size < 2
  abort <<EOF
Usage: a2t (-r) [xpath] [attr] < xml
       //xpath@attr <-> //xpath.text()
EOF
end
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
