
require "spec"

require File.dirname(__FILE__) + "/../lib/table_importer/table_importer.rb"


Contact = Struct.new(:first_name,:last_name,:full_name,:address,:user,:tags)
Reflection = Struct.new(:macro,:class_name)
Address = Struct.new(:street,:zip,:city,:tags)
User =Struct.new(:name,:address)
Tag =Struct.new(:tagging)