############################################################
# XMPPBot::Presence
# Simple wrapper for a StropheRuby::Stanza of type 'presence'
# Author : Francois Lamontagne
############################################################

module XMPPBot
  class Message
    attr_reader :stanza
    def initialize(stanza=nil)
      if stanza
        @stanza=stanza
      else
        @stanza=StropheRuby::Stanza.new
        @stanza.name="message"
        @stanza.type="chat"
      end
    end
  
    def from
      self.stanza.attribute("from") rescue nil
    end
  
    def from=(value)
      self.stanza.set_attribute("from",value.to_s)
    end
  
    def type
      self.stanza.type
    end
  
    def type=(type)
      self.stanza.type=type
    end
    
    def body
      self.stanza.child_by_name("body").text rescue nil
    end
  
    def body=(str)
      children = self.stanza.children
      
      #Strangely enough, sending a "<" character to our stream will terminate it.
      #I guess expat (the xml parser) should take care of encoding the
      #special characters to ensure that the xml remains valid... but it doesn't do it.
      str.gsub!(/[<>]/) {|s| s == "<" ? '&lt;' : '&gt;'}
      if children      
        children.children.text = str
      else  
        body_stanza = StropheRuby::Stanza.new
        body_stanza.name="body"
  
        text_stanza = StropheRuby::Stanza.new
        text_stanza.text=str
  
        body_stanza.add_child(text_stanza)    
        self.stanza.add_child(body_stanza)
      end
    end
  
    def to=(to)
      self.stanza.set_attribute("to",to)
    end    
  end
end