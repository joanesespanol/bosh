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


# ================================================================================
# UNIT TESTS
# ================================================================================

describe Bosh::AgilityCloud::Cloud do

  # ================================================================================
  # VARIABLES
  # ================================================================================

  let(:cpi) { double('AGILITY_CPI') }

  let(:mock_options) {
    {
      'agility' => {
        'url'      => 'https://<host>:<port>',
        'user'     => '<username>',
        'password' => '<password>'
      },
      'cpi' => cpi  # TODO: remove this
    }
  }

  let(:mock_networks) do  # TODO: make better network example
    {
      'network.0' => {
        'netmask'          => '255.255.248.0',
        'ip'               => '172.30.41.40',
        'gateway'          => '172.30.40.1',
        'dns'              => [ '172.30.22.153', '172.30.22.154' ],
        'cloud_properties' => { 'name' => 'VLAN444' }
      }
    }
  end

  let(:mock_metadata) do
    {
      'metadata.0' => 'value.0',
      'metadata.1' => 'value.1'
    }
  end


  # ================================================================================
  # TESTS
  # ================================================================================

  before :each do
    cpi.should_receive(:initialize).with(mock_options.to_json)
  end


  describe :initialize do
    it 'can be created using Bosh:Cloud:Provider' do
      cloud = Bosh::Clouds::Provider.create(:agility, mock_options)

      cloud.should be_an_instance_of(Bosh::AgilityCloud::Cloud)
      expect(cloud.cpi).to eql(cpi)
    end
  end


  describe :current_vm_id do
    it 'returns host virtual machine id' do
      cpi.should_receive(:currentVirtualMachineId).and_return('virtual.machine.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      virtual_machine_id = cloud.current_vm_id

      virtual_machine_id.should == 'virtual.machine.id'
    end
  end


  describe :create_stemcell do
    let(:mock_stem_cell_properties) do
      {
        'template' => {
          'name'          => '<name>',
          'stackName'     => '<stack_name>',
          'cloudProvider' => '<cloud_provider_name>',
          'location'      => '<location>',
          'credentials'   => '<credentials>',
          'hardwareModel' => '<hardware_model>'
        }
      }
    end

    it 'creates stem cell' do
      cpi.should_receive(:createStemCell)
         .with('image.path', mock_stem_cell_properties.to_json)
         .and_return('stem.cell.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      stem_cell_id = cloud.create_stemcell('image.path', mock_stem_cell_properties)

      stem_cell_id.should == 'stem.cell.id'
    end
  end


  describe :delete_stemcell do
    it 'deletes stem cell' do
      cpi.should_receive(:deleteStemCell).with('stem.cell.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.delete_stemcell('stem.cell.id')
    end
  end


  describe :create_vm do
    let(:mock_resource_pool) do
      {
        'resource.0' => 'value.0',
        'resource.1' => 'value.1'
      }
    end

    let(:mock_environment) do
      {
          'environment.0' => 'value.0',
          'environment.1' => 'value.1'
      }
    end

    it 'creates virtual machine with no locality and no environment' do
      cpi.should_receive(:createVirtualMachine)
         .with('agent.id', 'stem.cell.id', mock_resource_pool.to_json, mock_networks.to_json, nil, '{}')
         .and_return('virtual.machine.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      virtual_machine_id = cloud.create_vm('agent.id', 'stem.cell.id', mock_resource_pool, mock_networks)

      virtual_machine_id.should == 'virtual.machine.id'
    end

    it 'creates virtual machine with locality and environment' do
      cpi.should_receive(:createVirtualMachine)
         .with('agent.id', 'stem.cell.id', mock_resource_pool.to_json, mock_networks.to_json, %w(locality.0 locality.1), mock_environment.to_json)
        .and_return('virtual.machine.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      virtual_machine_id = cloud.create_vm('agent.id', 'stem.cell.id', mock_resource_pool, mock_networks, %w(locality.0 locality.1), mock_environment)

      virtual_machine_id.should == 'virtual.machine.id'
    end
  end


  describe :delete_vm do
    it 'deletes virtual machine' do
      cpi.should_receive(:deleteVirtualMachine).with('virtual.machine.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.delete_vm('virtual.machine.id')
    end
  end


  describe :has_vm? do
    it 'checks existing virtual machine' do
      cpi.should_receive(:hasVirtualMachine).with('virtual.machine.id').and_return(true)

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.has_vm?('virtual.machine.id').should == true
    end

    it 'checks non existing virtual machine' do
      cpi.should_receive(:hasVirtualMachine).with('virtual.machine.id').and_return(false)

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.has_vm?('virtual.machine.id').should == false
    end
  end


  describe :reboot_vm do
    it 'reboots virtual machine' do
      cpi.should_receive(:rebootVirtualMachine).with('virtual.machine.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.reboot_vm('virtual.machine.id')
    end
  end


  describe :set_vm_metadata do
    it 'set metadata for virtual machine' do
      cpi.should_receive(:setVirtualMachineMetadata).with('virtual.machine.id', mock_metadata.to_json)

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.set_vm_metadata('virtual.machine.id', mock_metadata)
    end
  end


  describe :configure_networks do
    it 'configures networks for virtual machine' do
      cpi.should_receive(:configureNetworks).with('virtual.machine.id', mock_networks.to_json)

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.configure_networks('virtual.machine.id', mock_networks)
    end

    # TODO
    # =========================================================================
    # There is no (easy) way to throw a Java exception (UnsupportedOperationException)
    # here.  The exception gets translated into a Rjb_JavaProxy object by Rjb,
    # and the rescue call in cloud.rb does not catch it.
    # So, for now, this test has been commented out, until a solution is found
    # on how to throw a "real" Java exception.
    # =========================================================================

    #it 'configures networks for virtual machine not supported' do
    #  cpi.should_receive(:configureNetworks)
    #     .with('virtual.machine.id', mock_networks.to_json)
    #    .and_throw(UnsupportedOperationException)
    #
    #  cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
    #
    #  expect {
    #    cloud.configure_networks('virtual.machine.id', mock_networks)
    #  }.to raise_error Bosh::Clouds::NotSupported
    #end
  end


  describe :create_disk do
    it 'creates disk with no locality' do
      cpi.should_receive(:createDisk).with(1234, nil).and_return('disk.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      disk_id = cloud.create_disk(1234)

      disk_id.should == 'disk.id'
    end

    it 'creates disk with locality' do
      cpi.should_receive(:createDisk).with(1234, 'virtual.machine.id').and_return('disk.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      disk_id = cloud.create_disk(1234, 'virtual.machine.id')

      disk_id.should == 'disk.id'
    end
  end


  describe :delete_disk do
    it 'deletes disk' do
      cpi.should_receive(:deleteDisk).with('disk.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.delete_disk('disk.id')
    end
  end


  # TODO: what about uses cases where the vm, or the disk do not exist?
  # TODO: similar question for other methods
  describe :attach_disk do
    it 'attaches disk to virtual machine' do
      cpi.should_receive(:attachDisk).with('virtual.machine.id', 'disk.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.attach_disk('virtual.machine.id', 'disk.id')
    end
  end


  describe :snapshot_disk do
    it 'snapshots disk with no metadata' do
      cpi.should_receive(:snapshotDisk).with('disk.id', '{}').and_return('snapshot.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      snapshot_id = cloud.snapshot_disk('disk.id')

      snapshot_id.should == 'snapshot.id'
    end

    it 'snapshots disk with metadata' do
      cpi.should_receive(:snapshotDisk).with('disk.id', mock_metadata.to_json).and_return('snapshot.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      snapshot_id = cloud.snapshot_disk('disk.id', mock_metadata)

      snapshot_id.should == 'snapshot.id'
    end
  end


  describe :delete_snapshot do
    it 'deletes snapshot' do
      cpi.should_receive(:deleteSnapshot).with('snapshot.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.delete_snapshot('snapshot.id')
    end
  end


  describe :detach_disk do
    it 'detaches disk to virtual machine' do
      cpi.should_receive(:detachDisk).with('virtual.machine.id', 'disk.id')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.detach_disk('virtual.machine.id', 'disk.id')
    end
  end


  describe :getDisks do
    it 'retrieve disks' do
      cpi.should_receive(:getDisks).with('virtual.machine.id').and_return(['disk.id.0', 'disk.id.1'])

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      disks = cloud.getDisks('virtual.machine.id')

      disks.should == ['disk.id.0', 'disk.id.1']
    end
  end


  describe :validate_deployment do
    it 'validate deployment' do
      cpi.should_receive(:validateDeployment).with('manifest.old', 'manifest.new')

      cloud = Bosh::AgilityCloud::Cloud.new(mock_options)
      cloud.validate_deployment('manifest.old', 'manifest.new')
    end
  end
end
