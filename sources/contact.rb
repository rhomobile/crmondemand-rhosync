require 'generic_oraclecrm_adapter'

class Contact < Generic_OracleCRM_Adapter
  def initialize(source,credential)
    super(source, credential)
    # initialize fields map
    @fields = []
    @fields << { "name" => "id", "oracle_name" => "Id"}
    @fields << { "name" => "FirstName", "oracle_name" => "ContactFirstName"}
    @fields << { "name" => "LastName", "oracle_name" => "ContactLastName"}
  end
 
  def login
    super
  end
 
  def query(params=nil)
    super(params)
  end
 
  def sync
    # Manipulate @result before it is saved, or save it 
    # yourself using the Rhosync::Store interface.
    # By default, super is called below which simply saves @result
    super
  end
 
  def create(create_hash,blob=nil)
    super(create_hash,blob)
  end
 
  def update(update_hash)
    super(update_hash)
  end
 
  def delete(delete_hash)
    super(delete_hash)
  end
 
  def logoff
    super
  end
end
