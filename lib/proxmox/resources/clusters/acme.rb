# frozen_string_literal: true

module Proxmox
  module Resources
    module Clusters
      # Proxmox Cluster Acme class
      class Acme
        def initialize(client)
          @client = client
        end

        def tos
          @client.request(:get, "/cluster/acme/tos")
        end
      end
    end
  end
end
