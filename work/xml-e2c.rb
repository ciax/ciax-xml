#!/usr/bin/ruby
# XML Create New Child Element and move Attribute to Child
require "optparse"
require "rexml/document"
include REXML

if ARGV.size < 2
  abort <<EOF
Usage: e2c [xpath] [child elem] < xml
       //xpath@attr -> //xpath/child@attr
EOF
end

xpath=ARGV.shift
child=ARGV.shift
doc=Document.new(gets(nil))
doc.each_element(xpath) {|e|
  a=e.attributes
  e.add_element(child,a)
  a.each_attribute { |attr| attr.remove }
}
puts doc
