# Copyright (c) 2013 ServiceMesh, Inc.

module Bosh
  module AgilityCloud; end
end

require "cloud"
require "cloud/agility"
require "cloud/agility/cloud"
require "cloud/agility/version"

module Bosh
  module Clouds
    Agility = Bosh::AgilityCloud::Cloud
  end
end
