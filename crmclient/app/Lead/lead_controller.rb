require 'rho/rhocontroller'
require 'helpers/browser_helper'

class LeadController < Rho::RhoController
  include BrowserHelper

  #GET /Lead
  def index
    @leads = Lead.find(:all)
    render :back => '/app'
  end

  # GET /Lead/{1}
  def show
    @lead = Lead.find(@params['id'])
    if @lead
      render :action => :show, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # GET /Lead/new
  def new
    @lead = Lead.new
    render :action => :new, :back => url_for(:action => :index)
  end

  # GET /Lead/{1}/edit
  def edit
    @lead = Lead.find(@params['id'])
    if @lead
      render :action => :edit, :back => url_for(:action => :index)
    else
      redirect :action => :index
    end
  end

  # POST /Lead/create
  def create
    puts " we are in create and : " + @params.inspect
    @lead = Lead.create(@params['lead'])
    redirect :action => :index
  end

  # POST /Lead/{1}/update
  def update
    @lead = Lead.find(@params['id'])
    @lead.update_attributes(@params['lead']) if @lead
    redirect :action => :index
  end

  # POST /Lead/{1}/delete
  def delete
    @lead = Lead.find(@params['id'])
    @lead.destroy if @lead
    redirect :action => :index  end
end
