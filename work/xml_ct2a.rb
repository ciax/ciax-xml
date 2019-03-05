#!/usr/bin/env ruby
# XML Child Text to Attribute
require 'optparse'
require 'rexml/document'
include REXML

if ARGV.size < 2
  abort <<EOF
Usage: ct2a [xpath] [child_elem(w/text)] < xml
       //xpath/attr.text() -> //xpath@attr
EOF
end

xpath = ARGV.shift
attr = ARGV.shift
doc = Document.new(gets(nil))
doc.each_element(xpath) do |e|
  cld = e.elements[attr] || next
  e.add_attribute(attr, cld.text)
  e.delete_element(attr)
end
puts doc
