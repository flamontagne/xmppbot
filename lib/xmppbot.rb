$:.unshift(File.dirname(__FILE__)) unless
   $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'strophe_ruby'
module XMPPBot
  VERSION = '0.0.1'  
end