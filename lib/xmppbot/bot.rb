############################################################
# XMPPBot::Bot
# Really simple implementation of StropheRuby to ease the devleopment process of a XMPP bot
# Author : Francois Lamontagne
############################################################
module XMPPBot
  class Bot
    attr_accessor :jid, :password, :log_level, :auto_accept_subscriptions      
    
    def initialize
      @send_lock = Mutex.new
    end
    
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
      x=Thread.new do
        Thread.current.abort_on_exception = true

        #that's our blocking call
        StropheRuby::EventLoop.run(@ctx)

        #cleanup and exit
        @conn.release
        @ctx.free        
        StropheRuby::EventLoop.shutdown
        main_thread.wakeup    
      end              
    end

    #accept subscription request from the user then send a subscription request to that same user.
    def accept_subscriptions
      on_presence_received do |pres|
        if pres.type == "subscribe"
          accept_subscription_from(pres.from)          
          subscribe_to(pres.from)
        end
      end
    end

    def accept_subscription_from(jid)
      p = Presence.new
      p.type = "subscribed"
      p.to=jid.scrap_resource
      self.send(p)
    end
    
    def subscribe_to(jid)
      p = Presence.new
      p.type = "subscribe"
      p.to = jid.scrap_resource
      self.send(p)    
    end
    
    def unsubscribe_from(jid)
      iq = StropheRuby::Stanza.new
      iq.name="iq"
      iq.type="set"
      
      query = StropheRuby::Stanza.new
      query.name="query"
      query.ns="jabber:iq:roster"
      
      item = StropheRuby::Stanza.new
      item.name="item"
      item.set_attribute("jid",jid.scrap_resource)
      item.set_attribute("subscription","remove")
      
      query.add_child(item)
      iq.add_child(query)
      send_stanza(iq)
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
    
    #send raw data to the stream
    def send_raw(str)
      @send_lock.synchronize do
        @conn.send_raw_string(str)
      end      
    end
    
    #You have to call this after a successful connection to notify everyone that you are online.
    #This is called the "initial presence" (see 5.1.1 at http://xmpp.org/rfcs/rfc3921.html)
    def announce_presence
      presence = StropheRuby::Stanza.new
      presence.name="presence"
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
      @send_lock.synchronize do
        @conn.send(stanza)
        @last_send=Time.now
      end                
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
