$:.unshift(File.dirname(__FILE__)) unless
   $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'strophe_ruby'
module XMPPBot
VERSION = '0.0.1'
    class Bot
        attr_accessor :jid, :password, :log_level, :auto_accept_subscriptions
      
        def connect
            StropheRuby::EventLoop.prepare
            @ctx=StropheRuby::Context.new(@log_level)
            @conn=StropheRuby::Connection.new(@ctx)
            @conn.jid = @jid
            @conn.password= @password
            @conn.connect do |status|
                accept_subscriptions if auto_accept_subscriptions
                keep_alive
                yield(status)
            end

            #FIXME: The following call works perfectly... but when you try stopping the program with CTRL-C, it produces a XMPP event watcher error.
            #See the run_once method in strophe/src/event.c for details. For now I do my own control loop and call run_once manually
            #Thread.new {EventLoop.run(@ctx)}

            return if @ctx.loop_status != 0
            @ctx.loop_status = 1        
            th= Thread.new do
                Thread.current.abort_on_exception = true    
                while (@ctx.loop_status == 1) do 
                    StropheRuby::EventLoop.run_once(@ctx, 1)
                end
                Thread.main.wakeup
            end            
        end

        def keep_alive
            Thread.new do
                loop do
                    difference = (@last_send || Time.now) + 90 - Time.now
                    if difference <= 0
                        self.announce_presence
                        sleep(90)
                    else
                        sleep(difference)
                    end
                end
            end
        end

        def accept_subscriptions    
            self.on_presence_received do |pres|
                if pres.stanza.type == "subscribe"
                    stanza = StropheRuby::Stanza.new
                    stanza.name = "presence"
                    stanza.type = "subscribed"
                    stanza.set_attribute("to",pres.stanza.attribute("from"))
                    self.send_stanza(stanza)
                    stanza.release
                    
                    stanza = StropheRuby::Stanza.new
                    stanza.name = "presence"
                    stanza.type = "subscribe"
                    stanza.set_attribute("to",pres.stanza.attribute("from"))
                    self.send_stanza(stanza)                    
                    stanza.release
                end
            end
        end

        def disconnect    
            StropheRuby::EventLoop.stop(@ctx)
            @conn.release
            @ctx.free
            StropheRuby::EventLoop.shutdown        
        end
        
        def send(obj)
            if obj.respond_to?(:stanza)
                send_stanza(obj.stanza)      
            else
                raise("native Stanza object has not been set")
            end
        end
        
        def send_stanza(stanza)
            @conn.send(stanza)
            @last_send=Time.now
        end

        def announce_presence
            presence = StropheRuby::Stanza.new
            presence.name="presence"
            presence.set_attribute("show", "available")
            self.send_stanza(presence)
            presence.release
        end

        def on_message_received
            @conn.add_handler("message") do |stanza|
                yield(Message.new(stanza)) if Message.new(stanza).body
            end
        end

        def on_presence_received
            @conn.add_handler("presence") do |stanza|
                yield(Presence.new(stanza))
            end
        end        
    end

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
    
    class ConnectionEvents
        CONNECT = StropheRuby::ConnectionEvents::CONNECT
        DISCONNECT = StropheRuby::ConnectionEvents::DISCONNECT
        FAIL = StropheRuby::ConnectionEvents::FAIL
    end
    
    class Logging
        INFO = StropheRuby::Logging::INFO
        WARN = StropheRuby::Logging::WARN
        ERROR = StropheRuby::Logging::ERROR
        DEBUG = StropheRuby::Logging::DEBUG
    end
end