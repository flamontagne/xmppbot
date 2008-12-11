############################################################
# XMPPBot::Bot
# Really simple implementation of StropheRuby to ease the devleopment process of a XMPP bot
# Author : Francois Lamontagne
############################################################

module XMPPBot
  class Bot
    attr_accessor :jid, :password, :log_level, :auto_accept_subscriptions
      
    #connect, authenticate and start event loop
    def connect
      StropheRuby::EventLoop.prepare
    
      @ctx=StropheRuby::Context.new(@log_level)
      @conn=StropheRuby::Connection.new(@ctx)
      @conn.jid = @jid
      @conn.password= @password
      
      @conn.connect do |status|
        if status == StropheRuby::ConnectionEvents::CONNECT
          accept_subscriptions if auto_accept_subscriptions
          keep_alive
        end
        yield(status)
      end

      main_thread = Thread.current      
          
      #start the event loop in a separate thread      
      Thread.new do
        Thread.current.abort_on_exception = true
        StropheRuby::EventLoop.run(@ctx)
      
        #shutdown down strophe and wake up the calling thread 
        StropheRuby::EventLoop.shutdown
        main_thread.wakeup
      end
    end

    #accept subscription request from the user then send a subscription request to that same user.
    def accept_subscriptions
      self.on_presence_received do |pres|
        if pres.stanza.type == "subscribe"
          p = Presence.new
          p.type = "subscribed"
          p.to=pres.from
          send(p)
    
          p = Presence.new
          p.type = "subscribe"
          p.to = pres.from
          send(p)
        end
      end
    end

    #Stop the event loop
    def disconnect
      StropheRuby::EventLoop.stop(@ctx)
    end
    
    #Send a message or presence object to the stream
    def send(obj)
      if obj.respond_to?(:stanza)
        send_stanza(obj.stanza)      
      else
        raise("Error: StropheRuby::Stanza object has not been set")
      end
    end
    
    #You have to call this after a successful connection to notify everyone that you are online.
    #This is called the "initial presence" (see 5.1.1 at http://xmpp.org/rfcs/rfc3921.html)
    def announce_presence
      presence = StropheRuby::Stanza.new
      presence.name="presence"
      presence.set_attribute("show", "available")
      send_stanza(presence)    
    end
    
    #callback for message stanzas. The parameter sent in the code block is the received Message object.    
    def on_message_received
      @conn.add_handler("message") do |stanza|
        yield(Message.new(stanza)) if Message.new(stanza).body
      end
    end
    
    #callback for presence stanzas. The parameter sent in the code block is the received Presence object.
    def on_presence_received
      @conn.add_handler("presence") do |stanza|
        yield(Presence.new(stanza))
      end
    end

    private        
    #Internal method that send the actual StropheRuby::Stanza object to the stream
    def send_stanza(stanza)
      @conn.send(stanza)
      @last_send=Time.now
    end
    
    #Signals to the xmpp server that we are still connected every X seconds
    #TODO: Investigate if it really helps keeping the connection alive
    def keep_alive
      Thread.new do
        loop do
          difference = (@last_send || Time.now) + 90 - Time.now
          if difference <= 0
            announce_presence
            sleep(90)
          else
            sleep(difference)
          end
        end
      end
    end                
  end
end