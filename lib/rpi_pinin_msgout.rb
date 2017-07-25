#!/usr/bin/env ruby

# file: rpi_pinin_msgout.rb

require 'rpi_pinin'
require 'morsecode'
require 'secret_knock'
require 'chronic_duration'
require 'morsecode_listener' 


class Echo

  def notice(s)
    puts "%s: %s" % [Time.now, s]
  end
end

class SecretKnockNotifier
  
  def initialize(notifier, topic: 'secretknock')
    
    @notifier, @topic = notifier, topic
    
  end
  
  def knock()
  end
  
  
  def message(s)
    @notifier.notice "%s: %s" % [@topic, s]
  end
end


class RPiPinInMsgOut < RPiPinIn
  
    
  HIGH = 1
  LOW = 0  

  # duration: Used by sample mode
  
  def initialize(id, pull: nil, mode: :default, verbose: true, 
                 subtopic: 'sensor', device_id: 'pi', notifier: Echo.new, 
                 duration: '5 seconds', index: 0, capture_rate: 0.5, 
                 descriptor: 'detected')
    
    super(id, pull: pull)
        
    @mode, @verbose, @notifier, @duration = mode, verbose, notifier, duration
    @capture_rate, @descriptor = capture_rate, descriptor
    @topic = [device_id, subtopic, index].join('/')
    @old_state = 'up'

  end
  
  def capture()

    if @mode == :default then
      
      setup { default_mode()  }    

    elsif @mode == :downup
      
      button_setup do |raw_state| 
          
        state =  raw_state == HIGH ? 'down' : 'up'          
        next if state == @old_state

        @notifier.notice "%s: button %s" % [@topic, state]
        @old_state = state
        
      end
      
    elsif @mode == :secretknock
      
      notifier = SecretKnockNotifier.new(@notifier, topic: @topic)
      
      sk = SecretKnock.new \
          short_delay: 0.55, long_delay: 1.1, external: notifier
      sk.detect

      setup { sk.knock }    
      
    elsif @mode == :morsecode
      
      on_message = -> (mc) do
        @notifier.notice "%s: %s" % [@topic, MorseCode.new(mc).to_s]        
      end
      
      mcl = MorseCodeListener.new &on_message
      
      button_setup(external: mcl)
      
    end
    
  end
  
  def capture_high()
       
    if @mode == :interval or @mode == :sample then
      
      count = 0
      
      duration = ChronicDuration.parse(@duration)
      
      t1 = Time.now - duration + 1      
      
      setup do 
        count, t1 = interval_mode(t1, count, duration) 
      end
      
    elsif @mode == :default
      
      setup { default_mode() }
      
    elsif @mode == :secretknock
      
      notifier = SecretKnockNotifier.new(@notifier, topic: @topic)
      
      sk = SecretKnock.new \
          short_delay: 0.55, long_delay: 1.1, external: notifier
      sk.detect

      setup { sk.knock }      
      
    end
    
  end
  
  
  private

  def button_setup(external: nil)
       
    self.watch do |state|

      name = state.to_i == 1 ? :on_keydown : :on_keyup
      external.method(name).call if external

      puts  Time.now.to_s + ': ' + state.to_s if @verbose

      yield state if block_given?
      
    end 
    
  end     
  
  def setup()
    
    t0 = Time.now + 1        
    
    self.watch_high do 

      # ignore any movements that happened a short time ago e.g. 250 
      #               milliseconds ago since the last movement
      if t0 + @capture_rate < Time.now then     
        
        puts  Time.now.to_s if @verbose
        
        yield() 
        
        t0 = Time.now
        
      else
        #puts 'ignoring ...'
      end   
      
    end # /watch_high
    
  end    
  
  def interval_mode(t1, count, duration)
                  
    count += 1
    
    elapsed = Time.now - (t1  + duration)

    if elapsed > 0 then

      # identify if the movement is consecutive
      msg = if elapsed < duration then              
        s = ChronicDuration.output(duration, :format => :long)
        "%s: %s %s times within the past %s" % [@topic, count, @descriptor, s ]
      else              
        "%s: %s" % [@topic, @descriptor]
      end
      
      @notifier.notice msg
      count, t1 = 0, Time.now

    end
    
    [count, t1]
        
  end    
  
  def default_mode()
    @notifier.notice "%s: %s" % [@topic, @descriptor]
  end
      
end