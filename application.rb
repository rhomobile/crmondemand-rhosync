require 'rest-client'

class Application < Rhosync::Base
  class << self
    def authenticate(username,password,session)
      puts "USER:#{username}, PASSWD: #{password}"
      success = false
      begin
        oraclecrm_url = Application.get_settings[:oraclecrm_service_url]
        request_url = oraclecrm_url + "?command=" + 'login'
        
        # here we just verifying the credetials
        # by loggin in and immediately logging out
        in_headers = {
          "UserName" => username,
          "Password" => password
        };

        RestClient.get(request_url, in_headers) do |response,request,result,&block|
          case response.code
          when 200
            # store password to be used by SourceAdaptors
            Store.set_value("#{username}:password", password)
            Store.put_value("#{username}:service_url", oraclecrm_url)
            
            # since we established the session only 
            # to verify the credentials - close the session here
            request_url = "#{oraclecrm_url}" + '?command=' + 'logoff'
            in_headers = { "Cookie" => response.headers[:set_cookie] };
            RestClient.get(request_url, in_headers)
          else
            raise "LOGIN/PASSWORD ERROR : #{response.code} : #{response}" 
          end  
        end
        success = true
      rescue Exception => e
        puts "LOGIN ERROR"
        puts e.inspect
        puts e.backtrace.join("\n")
        raise e
      end
      success
    end
    
    # Add hooks for application startup here
    # Don't forget to call super at the end!
    def initializer(path)
      super
    end

    def get_settings
      return @settings if @settings
      begin
        file = YAML.load_file(File.join(ROOT_PATH,'settings','settings.yml'))
        env = (ENV['RHO_ENV'] || :development).to_sym
        @settings = file[env]
      rescue Exception => e
        puts "Error opening settings file: #{e}"
        puts e.backtrace.join("\n")
        raise e
      end
    end
    
    # Calling super here returns rack tempfile path:
    # i.e. /var/folders/J4/J4wGJ-r6H7S313GEZ-Xx5E+++TI
    # Note: This tempfile is removed when server stops or crashes...
    # See http://rack.rubyforge.org/doc/Multipart.html for more info
    # 
    # Override this by creating a copy of the file somewhere
    # and returning the path to that file (then don't call super!):
    # i.e. /mnt/myimages/soccer.png
    def store_blob(object,field_name,blob)
      super #=> returns blob[:tempfile]
    end
  end
end

Application.initializer(ROOT_PATH)
