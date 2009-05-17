$:.unshift(File.dirname(__FILE__)) unless
   $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'strophe_ruby'
require 'xmppbot/bot'
require 'xmppbot/message'
require 'xmppbot/presence'
require 'xmppbot/other'
module XMPPBot
  VERSION="0.0.3"
end
