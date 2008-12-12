############################################################# 
# Some other StropheRuby wrappers 
# Author : Francois Lamontagne
############################################################

module XMPPBot
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

class String
    def scrap_resource
	self.match(/[^\/]*/i).to_s
    end
    
    def resource
	self.match(/\/.*/i).to_s.delete("/")
    end
    
    def node
	self.match(/[^\@]*/i).to_s
    end
end
