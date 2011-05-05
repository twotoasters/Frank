Given /^I launch the app$/ do

  # kill the app if it's already running, just in case this helps 
  # reduce simulator flakiness when relaunching the app. Use a timeout of 5 seconds to 
  # prevent us hanging around for ages waiting for the ping to fail if the app isn't running
  begin
    Timeout::timeout(5) { press_home_on_simulator if frankly_ping }
  rescue Timeout::Error 
  end

  app_path = (ENV['APP_BUNDLE_PATH'] || APP_BUNDLE_PATH).chomp
  raise "APP_BUNDLE_PATH was not set. \nPlease set a APP_BUNDLE_PATH ruby constant or environment variable to the path of your compiled Frankified iOS app bundle" if app_path.nil?
  
  require 'uispecrunner'
  
  num_timeouts = 0
  loop do
    begin
      fork do
        config = UISpecRunner.new(:app_path => app_path, :driver => :waxsim, :family => :iphone, :sdk_version => '4.3', :verbose => true)
        waxsim_runner = UISpecRunner::Drivers::WaxSim.new(config)
        waxsim_runner.run_specs({})
      end
      
      wait_for_frank_to_come_up
      break # if we make it this far without an exception then we're good to move on

    rescue Timeout::Error
      num_timeouts += 1
      puts "Encountered #{num_timeouts} timeouts while launching the app."
      if num_timeouts > 3
        raise "Encountered #{num_timeouts} timeouts in a row while trying to launch the app." 
      end
    end
  end

  # TODO: do some kind of waiting check to see that your initial app UI is ready
  # e.g. Then "I wait to see the login screen"

end
