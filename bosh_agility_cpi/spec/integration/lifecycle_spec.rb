# ================================================================================
#
# Copyright (C) 2013-2014 ServiceMesh, Inc.
# 233 Wilshire Blvd, Suite 990, Santa Monica, CA 90401
# All rights reserved.  Confidential and Proprietary.
#
# This information is provided under the Master Supply Agreement between the
# parties and is considered a portion of the Licensed Software and Confidential
# Information as defined therein.
# This information is provided "as is" without warranty of any kind either
# expressed or implied, including, but not limited to, the implied warranties
# of merchantability and/or fitness for a particular purpose.
#
# ================================================================================


# ================================================================================
# INITIALIZATION
# ================================================================================

require 'spec_helper'
require 'logger'


# ================================================================================
# INTEGRATION TESTS
# ================================================================================

describe Bosh::AgilityCloud::Cloud do

  # ================================================================================
  # CONFIGURATION
  # ================================================================================

  # ----------  Configuration  ----------
  before(:all) do
    @agility_url                     = ENV['BOSH_AGILITY_URL']                     || raise('Missing BOSH_AGILITY_URL')
    @agility_user                    = ENV['BOSH_AGILITY_USER']                    || raise('Missing BOSH_AGILITY_USER')
    @agility_password                = ENV['BOSH_AGILITY_PASSWORD']                || raise('Missing BOSH_AGILITY_PASSWORD')
    @agility_template_stack_name     = ENV['BOSH_AGILITY_TEMPLATE_STACK_NAME']     || raise('Missing BOSH_AGILITY_TEMPLATE_STACK_NAME')
    @agility_template_cloud_provider = ENV['BOSH_AGILITY_TEMPLATE_CLOUD_PROVIDER'] || raise('Missing BOSH_AGILITY_TEMPLATE_CLOUD_PROVIDER')
    @agility_template_location       = ENV['BOSH_AGILITY_TEMPLATE_LOCATION']       || raise('Missing BOSH_AGILITY_TEMPLATE_LOCATION')
    @agility_template_credentials    = ENV['BOSH_AGILITY_TEMPLATE_CREDENTIALS']    || raise('Missing BOSH_AGILITY_TEMPLATE_CREDENTIALS')
    @agility_template_hardware_model = ENV['BOSH_AGILITY_TEMPLATE_HARDWARE_MODEL'] || raise('Missing BOSH_AGILITY_TEMPLATE_HARDWARE_MODEL')
  end

  subject(:cpi) do
    described_class.new(
      'agility' => {
        'url'      => @agility_url,
        'user'     => @agility_user,
        'password' => @agility_password,
      }
    )
  end

  # ----------  Setup logger  ----------
  before { Bosh::Clouds::Config.stub(logger: logger) }

  let(:logger) { Logger.new(STDERR) }

  # ----------  Clean up  ----------
  after  { cpi.close if cpi }

  #before { @template_id = nil }
  #after  { cpi.delete_stemcell(@template_id) if @template_id }
  #
  #before { @instance_id = nil }
  #after  { cpi.delete_vm(@instance_id) if @instance_id }

  before { @volume_id = nil }
  after  { cpi.delete_disk(@volume_id) if @volume_id }


  # ================================================================================
  # LIFECYCLE TESTS
  # ================================================================================

  it 'should exercise the vm lifecycle' do
    # ----------  Create stem cell  ----------
#begin
#cpi.configure_networks(
#    "vm.id",
#    {}
#);
#rescue Bosh::Clouds::NotSupported
#end

    @template_id = cpi.create_stemcell(
      nil,
      {
        'template' => {
          'name'          => '',
          'stackName'     => @agility_template_stack_name,
          'cloudProvider' => @agility_template_cloud_provider,
          'location'      => @agility_template_location,
          'credentials'   => @agility_template_credentials,
          'hardwareModel' => @agility_template_hardware_model
        }
      }
    )

    @template_id.should_not be_nil

    # ----------  Create virtual machine  ----------
    resource_pool = {}
    networks      = {}
    disk_locality = []
    environment   = {}

    @instance_id = cpi.create_vm(
      "agent.id",
      @template_id,
      resource_pool,
      networks,
      disk_locality,
      environment
    )

    @instance_id.should_not be_nil
    cpi.has_vm?(@instance_id).should be(true)

    # ----------  Set virtual machine metadata  ----------
    cpi.set_vm_metadata(
      @instance_id,
      {
        'metadata.0' => 'value.0',
        'metadata.1' => 'value.1'
      }
    )

    # ----------  Delete virtual machine  ----------
    #cpi.delete_vm(@instance_id)
    #cpi.has_vm?(@instance_id).should be(false)

    # ----------  Delete stem cell  ----------
    #cpi.delete_stemcell(@template_id)
  end
end
