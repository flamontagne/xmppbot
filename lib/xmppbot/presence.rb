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
        @stanza.name = "presence"
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
  
    def show
      s=self.stanza.child_by_name("show")
      s ? s.text : nil
    end
    
    #returns the show (away, dnd, chat,xa). if there is none, returns the type which can be : unavailable
    #subscribe,subscribed,unsubscribe,unsubscribed,probe or error.
    def to_s
      res = self.show
      res ? res : self.type.to_s
    end
  end
end