require 'rho/rhocontroller'
require 'helpers/browser_helper'

class ContactController < Rho::RhoController
  include BrowserHelper

  #GET /Contact
  def index
    @contacts = Contact.find(:all)
    render :back => '/app'
  end

  # GET /Contact/{1}
  def show
    @contact = Contact.find(@params['id'])
    if @contact
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Contact/new
  def new
    @contact = Contact.new
    puts Contact.metadata.inspect
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Contact/{1}/edit
  def edit
    @contact = Contact.find(@params['id'])
    if @contact
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Contact/create
  def create
    @contact = Contact.create(@params['contact'])
    redirect :action => :index
  end

  # POST /Contact/{1}/update
  def update
    @contact = Contact.find(@params['id'])
    @contact.update_attributes(@params['contact']) if @contact
    redirect :action => :index
  end

  # POST /Contact/{1}/delete
  def delete
    @contact = Contact.find(@params['id'])
    @contact.destroy if @contact
    redirect :action => :index  end
end
