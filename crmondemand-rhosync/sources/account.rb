require 'generic_oraclecrm_adapter'

class Account < Generic_OracleCRM_Adapter 
  def initialize(source,credential)
    super(source, credential)
  end
 
  def login
    super
    # initialize fields map
  end
 
  def query(params=nil)
    super(params)
  end
  
  def metadata
    super
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
    # TODO: Logout from the data source if necessary
    super
  end
end
