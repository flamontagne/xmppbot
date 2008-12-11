############################################################
# XMPPBot::Presence
# Simple wrapper for a StropheRuby::Stanza of type 'presence'
# Author : Francois Lamontagne
############################################################

module XMPPBot
  class Presence
    attr_reader :stanza  
  
    def initialize(stanza=nil)
      if stanza
        @stanza=stanza
      else
        @stanza = StropheRuby::Stanza.new
      end
    end
  
    def from
      self.stanza.attribute("from")
    end
  
    def to
      self.stanza.attribute("to")
    end
  
    def to=(to)
      self.stanza.set_attribute("to",to)
    end
  
    def type
      self.stanza.type
    end
  
    def type=(type)
      self.stanza.type=type
    end
  
    def to_s
      self.stanza.child_by_name("show").text rescue "available"
    end
  end
end