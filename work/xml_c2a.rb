#!/usr/bin/ruby
# XML Child Element with Text to Attribute Converter
require 'optparse'
require 'rexml/document'
include REXML

if ARGV.size < 2
  abort <<EOF
Usage: c2a [xpath] [child_elem(w/text)] < xml
       //xpath/attr.text() -> //xpath@attr
EOF
end

xpath = ARGV.shift
attr = ARGV.shift
doc = Document.new(gets(nil))
doc.each_element(xpath) do|e|
  c = e.elements[attr] || next
  e.add_attribute(attr, c.text)
  e.delete_element(attr)
end
puts doc
