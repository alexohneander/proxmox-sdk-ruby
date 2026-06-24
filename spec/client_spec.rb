# frozen_string_literal: true

require "spec_helper"

RSpec.describe Proxmox::Client do
  let(:base_url) { "https://pve.example.com:8006" }
  let(:username) { "root" }
  let(:password) { "secret" }

  subject(:client) do
    # We stub login to avoid network calls during initialization
    allow_any_instance_of(Proxmox::Client).to receive(:login)
    described_class.new(
      base_url: base_url,
      username: username,
      password: password
    )
  end

  describe "#cluster" do
    it "returns a Cluster resource" do
      expect(client.cluster).to be_a(Proxmox::Resources::Cluster)
    end

    it "memoizes the cluster resource" do
      expect(client.cluster).to be(client.cluster)
    end
  end

  describe "#node" do
    it "returns a Node resource" do
      node = client.node("pve1")
      expect(node).to be_a(Proxmox::Resources::Node)
    end

    it "initializes with the correct node name" do
      node = client.node("pve1")
      expect(node.name).to eq("pve1")
    end
  end

  describe "#nodes" do
    let(:nodes_response) do
      [
        { "node" => "pve1", "status" => "online", "cpu" => 0.1 },
        { "node" => "pve2", "status" => "offline" }
      ]
    end

    before do
      allow(client).to receive(:request).with(:get, "/nodes").and_return(nodes_response)
    end

    it "returns an array of Node resources" do
      nodes = client.nodes
      expect(nodes).to be_an(Array)
      expect(nodes.first).to be_a(Proxmox::Resources::Node)
      expect(nodes.size).to eq(2)
    end

    it "hydrates the node objects with data" do
      node = client.nodes.first
      expect(node.name).to eq("pve1")
      expect(node).to be_online
      expect(node.cpu).to eq(0.1)
    end
  end
end
