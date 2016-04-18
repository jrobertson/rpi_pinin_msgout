#!/usr/bin/env ruby

# file: rpi_pinin_msgout.rb

require 'rpi_pinin'
require 'chronic_duration'


class Echo

  def notice(s)
    puts "%s: %s" % [Time.now, s]
  end
end

class RPiPinInMsgOut < RPiPinIn


  def initialize(id, pull: nil, mode: :default, verbose: true, 
                 subtopic: 'sensor', device_id: 'pi', notifier: Echo.new, 
                 duration: '5 seconds', index: 0, capture_rate: 0.5, 
                 descriptor: 'detected')
    
    super(id, pull: pull)
        
    @mode, @verbose, @notifier, @duration = mode, verbose, notifier, duration
    @capture_rate, @descriptor = capture_rate, descriptor
    @topic = [device_id, subtopic, index].join('/')
    
  end
  
  def capture()
   
    case @mode
      
    when :default
      setup { default_mode() }
    end
    
  end  

  def capture_high()
   
    case @mode
    when :interval
      
      count = 0
      
      duration = ChronicDuration.parse(@duration)
      
      t1 = Time.now - duration + 1      
      
      setup do 
        count, t1 = interval_mode(t1, count, duration) 
      end
      
    when :default
      setup { default_mode() }
    end
    
  end
  
  private
  
  def button_setup()
    
    t0 = Time.now + 1        
    
    self.watch do |v|

      # ignore any movements that happened a short time ago e.g. 250 
      #               milliseconds ago since the last movement
      if t0 + @capture_rate < Time.now then     
        
        puts  Time.now.to_s if @verbose
        
        yield(v) 
        
        t0 = Time.now
        
      else
        #puts 'ignoring ...'
      end   
      
    end # /watch 
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