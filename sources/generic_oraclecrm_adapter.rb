require 'rest-client'
require 'savon'

class Generic_OracleCRM_Adapter < SourceAdapter 
  def initialize(source,credential)
    super(source, credential)
    puts "Initializing ORACLE CRM " + self.class.to_s + " SourceAdapter"
    @oraclecrm_object = "#{self.class.to_s}"
    @soap_client = Savon::Client.new
    # comment the following lines 
    # to see the SOAP request going over the HTTP
    Savon.configure do |config|
      config.log = false
    end
    @soap_client.wsdl.document = File.join(ROOT_PATH, "wsdl/#{self.class.to_s}.wsdl")

    # initialize fields map
    @fields = []
  end
 
  def login
    puts "LOGIN USER: #{current_user.login}" 
    @endpoint_url = Store.get_value("#{current_user.login}:service_url")
    
    password = Store.get_value("#{current_user.login}:password")
    # credentials will be passed with every request (stateless)
    @soap_client.wsse.credentials("#{current_user.login}", password)
    @soap_client.wsdl.endpoint = @endpoint_url + "/#{self.class.to_s}"  
  end
 
  def query(params=nil)
    # TODO: Query your backend data source and assign the records 
    # to a nested hash structure called @result. For example:
    # @result = { 
    #   "1"=>{"name"=>"Acme", "industry"=>"Electronics"},
    #   "2"=>{"name"=>"Best", "industry"=>"Software"}
    # }
    querypage_prefix = "#{@oraclecrm_object}" + 'QueryPage'
    soapaction = '"document/' + @soap_client.wsdl.namespace + ':'
    soapaction += querypage_prefix + '"'

    request_fields = {}
    @fields.each do |f|
      request_fields[f["oracle_name"]] = ''
    end
    request_body = {
      "#{@oraclecrm_object}" => request_fields,  
      :attributes! => { "#{@oraclecrm_object}" => { "searchspec" => "" } } 
    };

    @result = {}
    fetch_more = 'true'
    start_row = 0
    begin 
      soap_body = {
        "ListOf#{@oraclecrm_object}" => request_body,
        :attributes! => { 
          "ListOf#{@oraclecrm_object}" => { 
            "recordcountneeded" => true, 
            "pagesize" => "100", 
            "startrownum" => "#{start_row.to_s}" 
          }
        }
      }
 
      response = @soap_client.request(:wsdl, querypage_prefix + '_Input') do
        http.headers["SOAPAction"] = soapaction
        if @session_cookie != nil
          http.headers["Cookie"] = @session_cookie
        end
        soap.body = soap_body
      end
      # server stateless session id is returned with the response
      @session_cookie = response.http.headers["Set-Cookie"]

      query_results = Nori.parse(response.http.body)["SOAP_ENV:Envelope"]["SOAP_ENV:Body"]["ns:#{querypage_prefix}_Output"]["ListOf#{@oraclecrm_object}"]
      fetch_more = query_results['@lastpage'] == 'true' ? false : true

      query_results.each do |objname,records|
        if objname == "#{@oraclecrm_object}"
          # in case of single record - it comes as a Hash
          # otherwise it is an array of record Hashes
          if records.is_a?Hash
            records = [records]
          end
          records.each do |oracle_rec|
            id_field = oracle_rec["Id"]
            converted_record = {}
            # grab only the allowed fields 
            # and map oracle field names into RhoSync field names
            @fields.each do |f|
              converted_record[f["name"]] = oracle_rec[f["oracle_name"]]
            end
            @result["#{id_field.to_s}"] = converted_record
          end
        end
      end
      start_row = @result.size
    end while fetch_more
    @result
  end
 
  def sync
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash,blob=nil)
    # TODO: Create a new record in your backend data source
    # If your rhodes rhom object contains image/binary data 
    # (has the image_uri attribute), then a blob will be provided
    created_object_id = nil
    insert_prefix = "#{@oraclecrm_object}" + 'Insert'
    soapaction = '"document/' + @soap_client.wsdl.namespace + ':'
    soapaction += insert_prefix + '"'

    request_fields = {}
    @fields.each do |f|
      field_value = create_hash[f['name']]
      if field_value != nil
        request_fields[f['oracle_name']] = field_value
      end
    end
    request_body = {
      "#{@oraclecrm_object}" => request_fields 
    };

    soap_body = {
      "ListOf#{@oraclecrm_object}" => request_body
    };
 
    begin 
      response = @soap_client.request(:wsdl, insert_prefix + '_Input') do
        http.headers["SOAPAction"] = soapaction
        if @session_cookie != nil
          http.headers["Cookie"] = @session_cookie
        end
        soap.body = soap_body
      end

      # get the create object id
      oracle_rec = Nori.parse(response.http.body)["SOAP_ENV:Envelope"]["SOAP_ENV:Body"]["ns:#{insert_prefix}_Output"]["ListOf#{@oraclecrm_object}"]
      created_object_id = oracle_rec["#{@oraclecrm_object}"]["Id"]
    rescue Savon::Error => e
      raise e
    end
    # server stateless session id is returned with the response
    @session_cookie = response.http.headers["Set-Cookie"]
    
    # return new object ids
    created_object_id
  end
 
  def update(update_hash)
    updated_object_id = nil
    update_prefix = "#{@oraclecrm_object}" + 'Update'
    soapaction = '"document/' + @soap_client.wsdl.namespace + ':'
    soapaction += update_prefix + '"'
    request_fields = {}

    @fields.each do |f|
      field_value = update_hash[f['name']]
      if field_value != nil
        request_fields[f['oracle_name']] = field_value
      end
    end
    request_body = {
      "#{@oraclecrm_object}" => request_fields 
    };

    soap_body = {
      "ListOf#{@oraclecrm_object}" => request_body
    };
 
    begin 
      response = @soap_client.request(:wsdl, update_prefix + '_Input') do
        http.headers["SOAPAction"] = soapaction
        if @session_cookie != nil
          http.headers["Cookie"] = @session_cookie
        end
        soap.body = soap_body
      end

      updated_object_id = update_hash['id']
    rescue Savon::Error => e
      raise e
    end
    # server stateless session id is returned with the response
    @session_cookie = response.http.headers["Set-Cookie"]
    
    updated_object_id
  end
 
  def delete(delete_hash)
    deleted_object_id = nil
    delete_prefix = "#{@oraclecrm_object}" + 'Delete'
    soapaction = '"document/' + @soap_client.wsdl.namespace + ':'
    soapaction += delete_prefix + '"'
    request_fields = {}

    @fields.each do |f|
      field_value = delete_hash[f['name']]
      if field_value != nil
        request_fields[f['oracle_name']] = field_value
      end
    end
    request_body = {
      "#{@oraclecrm_object}" => request_fields 
    };

    soap_body = {
      "ListOf#{@oraclecrm_object}" => request_body
    };
 
    begin 
      response = @soap_client.request(:wsdl, delete_prefix + '_Input') do
        http.headers["SOAPAction"] = soapaction
        if @session_cookie != nil
          http.headers["Cookie"] = @session_cookie
        end
        soap.body = soap_body
      end

      deleted_object_id = delete_hash['id']
    rescue Savon::Error => e
      raise e
    end
    # server stateless session id is returned with the response
    @session_cookie = response.http.headers["Set-Cookie"]
    
    deleted_object_id
  end
 
  def logoff
    # logoff if necessary
  end
end
