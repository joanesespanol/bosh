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

# ----------  Configuration  ----------

require 'json'  # Needed to convert Ruby hashes to a JSON string for Java
require 'rjb'   # Bridge between the Ruby and Java worlds

$VERBOSE=true   # Option for RJB
$DEBUG=true     # Option for RJB


# ----------  Load CPI  ----------

# On Windows (depending on the Ruby installation), make sure to use a 32bit JDK
# (set JAVA_HOME=<path to a 32bit JDK>).

# TODO: where to get the jar from?  Should probably be a relative path
Rjb::load(classpath='E:/ServiceMesh/Development/Github/joanesespanol/field-swat/swat/jespanol/CloudFoundry/CPI/target/cpi-main-SNAPSHOT-jar-with-dependencies.jar', jvmargs=[])

# Import the Java implementation of the Agility CPI
AGILITY_CPI = Rjb::import('com.servicemesh.cloudfoundry.cpi.AgilityCPI')


# ================================================================================
# MODULE
# ================================================================================

module Bosh::AgilityCloud

  class Cloud < Bosh::Cloud
    # ================================================================================
    # VARIABLES
    # ================================================================================

    attr_accessor :cpi
    #attr_accessor :logger


    # ================================================================================
    # PUBLIC METHODS
    # ================================================================================

    ##
    # Initializes the cloud provider.
    #
    # Options example:
    #  {
    #    'agility' => {
    #      'url'      => 'https://<host>:<port>',
    #      'user'     => '<username>',
    #      'password' => '<password>'
    #    }
    #  }
    #
    # @param [Hash] options - cloud options
    #
    # @return [void]
    #
    def initialize(options)
      ##@logger = Bosh::Clouds::Config.logger

      # TODO: remove the ugly options['cpi'] used only during testing - learn how to mock this
      @cpi = options['cpi'] || AGILITY_CPI.new
      @cpi.initialize(options.to_json)
    end


    ##
    # Returns the vm_id of this host.
    #
    # @return [String] - opaque id later used by other methods of the CPI
    #
    def current_vm_id
      @cpi.currentVirtualMachineId
    end


    ##
    # Creates a stemcell.
    #
    # @param [String] image_path       - path to an opaque blob containing the stemcell image
    # @param [Hash]   cloud_properties - properties required for creating this template specific to a CPI
    #
    # @return [String] - opaque id later used by {#create_vm} and {#delete_stemcell}
    #
    def create_stemcell(image_path, cloud_properties)
      @cpi.createStemCell(image_path, cloud_properties.to_json)
    end


    ##
    # Deletes a stemcell.
    #
    # @param [String] stemcell - stemcell id that was once returned by {#create_stemcell}
    #
    # @return [void]
    #
    def delete_stemcell(stemcell_id)
      @cpi.deleteStemCell(stemcell_id)
    end

    ##
    # Creates a VM - creates (and powers on) a VM from a stemcell with the
    # proper resources and on the specified network. When disk locality is
    # present the VM will be placed near the provided disk so it won't have
    # to move when the disk is attached later.
    #
    # Sample networking config:
    #  {
    #    "network_a" => {
    #      "netmask"          => "255.255.248.0",
    #      "ip"               => "172.30.41.40",
    #      "gateway"          => "172.30.40.1",
    #      "dns"              => [ "172.30.22.153", "172.30.22.154" ],
    #      "cloud_properties" => { "name" => "VLAN444" }
    #    }
    #  }
    #
    # Sample resource pool config (CPI specific):
    #  {
    #    "ram"  => 512,
    #    "disk" => 512,
    #    "cpu"  => 1
    #  }
    # or similar for EC2:
    #  {
    #    "name" => "m1.small"
    #  }
    #
    # @param [String]                  agent_id      - UUID for the agent that will be used later on by the director to locate and talk to the agent
    # @param [String]                  stemcell      - stemcell id that was once returned by {#create_stemcell}
    # @param [Hash]                    resource_pool - cloud specific properties describing the resources needed for this VM
    # @param [Hash]                    networks      - list of networks and their settings needed for this VM
    # @param [optional, String, Array] disk_locality - disk id(s) if known of the disk(s) that will be attached to this vm
    # @param [optional, Hash]          env           - environment that will be passed to this vm
    #
    # @return [String] - opaque id later used by {#configure_networks}, {#attach_disk}, {#detach_disk}, and {#delete_vm}
    #
    def create_vm(agent_id, stemcell_id, resource_pool, networks, disk_locality = nil, env = nil)
      @cpi.createVirtualMachine(
        agent_id,
        stemcell_id,
        resource_pool.to_json,
        networks.to_json,
        disk_locality,
        env.nil? ? "{}" : env.to_json
      ) # TODO: convert disk_locality to array ?
    end


    ##
    # Deletes a VM.
    #
    # @param [String] vm vm - id that was once returned by {#create_vm}
    #
    # @return [void]
    #
    def delete_vm(vm_id)
      @cpi.deleteVirtualMachine(vm_id)
    end


    ##
    # Checks if a VM exists.
    #
    # @param [String] vm_id - vm id that was once returned by {#create_vm}
    #
    # @return [Boolean] - True if the vm exists
    #
    def has_vm?(vm_id)
      @cpi.hasVirtualMachine(vm_id)
    end


    ##
    # Reboots a VM.
    #
    # @param [String]         vm_id - vm id that was once returned by {#create_vm}
    # @param [Optional, Hash] CPI specific options (e.g hard/soft reboot) # TODO: what is this option?
    #
    # @return [void]
    #
    def reboot_vm(vm_id)
      @cpi.rebootVirtualMachine(vm_id)
    end


    ##
    # Sets metadata for a VM.
    #
    # Optional. Implement to provide more information for the IaaS.
    #
    # @param [String] vm_id    - vm id that was once returned by {#create_vm}
    # @param [Hash]   metadata - metadata key/value pairs
    #
    # @return [void]
    #
    def set_vm_metadata(vm_id, metadata)
      @cpi.setVirtualMachineMetadata(vm_id, metadata.to_json)
    end


    ##
    # Configures networking on an existing VM.
    #
    # @param [String] vm_id    - vm id that was once returned by {#create_vm}
    # @param [Hash]   networks - list of networks and their settings needed for this VM, same as the networks argument in {#create_vm}
    #
    # @return [void]
    #
    def configure_networks(vm_id, networks)
      begin
        @cpi.configureNetworks(vm_id, networks.to_json)
      rescue UnsupportedOperationException => uoe
        raise Bosh::Clouds::NotSupported, uoe.message
      end
    end


    ##
    # Creates a disk (possibly lazily) that will be attached later to a VM. When
    # VM locality is specified the disk will be placed near the VM so it won't
    # have to move when it's attached later.
    #
    # @param [Integer]          size        - disk size in MB
    # @param [optional, String] vm_locality - vm id if known of the VM that this disk will be attached to
    #
    # @return [String] - opaque id later used by {#attach_disk}, {#detach_disk}, and {#delete_disk}
    #
    def create_disk(size, vm_locality = nil)
      @cpi.createDisk(size, vm_locality)
    end


    ##
    # Deletes a disk.
    # Will raise an exception if the disk is attached to a VM.
    #
    # @param [String] disk - disk id that was once returned by {#create_disk}
    #
    # @return [void]
    #
    def delete_disk(disk_id)
      @cpi.deleteDisk(disk_id)
    end


    ##
    # Attaches a disk.
    #
    # @param [String] vm_id - vm id that was once returned by {#create_vm}
    # @param [String] disk  - disk id that was once returned by {#create_disk}
    #
    # @return [void]
    #
    def attach_disk(vm_id, disk_id)
      @cpi.attachDisk(vm_id, disk_id)
    end


    ##
    # Takes snapshot of a disk.
    #
    # @param [String] disk_id - disk id of the disk to take the snapshot of
    #
    # @return [String] - snapshot id
    #
    def snapshot_disk(disk_id, metadata={})
      @cpi.snapshotDisk(disk_id, metadata.to_json)
    end


    ##
    # Deletes a disk snapshot.
    #
    # @param [String] snapshot_id - snapshot id to delete
    #
    # @return [void]
    #
    def delete_snapshot(snapshot_id)
      @cpi.deleteSnapshot(snapshot_id)
    end


    ##
    # Detaches a disk.
    #
    # @param [String] vm_id - vm id that was once returned by {#create_vm}
    # @param [String] disk  - disk id that was once returned by {#create_disk}
    #
    # @return [void]
    #
    def detach_disk(vm_id, disk_id)
      @cpi.detachDisk(vm_id, disk_id)
    end


    ##
    # Lists the attached disks of the VM.
    #
    # @param [String] vm_id - CPI-standard vm_id (eg, returned from current_vm_id)
    #
    # @return [array[String]] - list of opaque disk_ids that can be used with the other disk-related methods on the CPI
    #
    def getDisks(vm_id)
      @cpi.getDisks(vm_id)
    end

    ##
    # Validates the deployment.
    #
    # @api not_yet_used
    #
    def validate_deployment(old_manifest, new_manifest)
      @cpi.validateDeployment(old_manifest, new_manifest)
    end


    ##
    # Closes the cpi.
    #
    # TODO: How will this be called from Bosh?  Is there a way to have it called automatically?
    #
    def close
      @cpi.close
    end


    # ================================================================================
    # PRIVATE METHODS
    # ================================================================================

    private

    ##
    # Raises CloudError exception.
    #
    # @param [String]              message   - Message about what went wrong
    # @param [Optional, Exception] exception - Exception to be logged (optional)
    #
    def cloud_error(message, exception = nil)
      @logger.error(message) if @logger
      @logger.error(exception) if @logger && exception
      raise Bosh::Clouds::CloudError, message
    end
  end
end
