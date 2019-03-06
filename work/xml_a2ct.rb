#!/usr/bin/env ruby
# XML Attribute to Child Text
#alias a2ct
require 'optparse'
require 'rexml/document'
include REXML

if ARGV.size < 2
  abort <<EOF
Usage: a2ct (-r) [xpath] [attr] < xml
       //xpath@attr <-> //xpath/attr.text()
EOF
end

xpath = ARGV.shift
attr = ARGV.shift
doc = Document.new(gets(nil))
doc.each_element(xpath) do |e|
  str = e.attributes[attr] || next
  e.delete_attribute(attr)
  # If str includes ',', child will be added as the number of csv elements
  str.split(',').each{ |s| e.add_element(attr).text = s }
end
doc.write
