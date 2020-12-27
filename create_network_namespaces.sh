#!/bin/bash

# This script shows how to create two network namespaces per node in a multi node environment. Bridge is used to make communication possiblle between the namespaces in a given node.
# Ip of this node: 172.168.0.4
# Ip of another node: 172.168.0.5
# Namespace ip range of this node: 172.16.0.1
# Namespace ip range of the another node: 176.16.1.0

echo "Creating the namespaces..."
sudo ip netns add $ns_1
sudo ip netns add $ns_2

echo "Creating the veth pairs..."
sudo ip link add veth-$ns_1 type veth peer name veth-$ns_1-br
sudo ip link add veth-$ns_2 type veth peer name veth-$ns_2-br

echo "Adding the veth pairs to the namespaces..."
sudo ip link set veth-$ns_1 netns $ns_1
sudo ip link set veth-$ns_2 netns $ns_2

echo "Configuring the interfaces in the network namespaces with IP address..."
sudo ip netns exec $ns_1 ip addr add 172.16.0.2/24 dev veth-$ns_1 
sudo ip netns exec $ns_2 ip addr add 172.16.0.3/24 dev veth-$ns_" 

echo "Enabling the interfaces inside the network namespaces..."
sudo ip netns exec $ns_1 ip link set dev veth-$ns_1 up
sudo ip netns exec $ns_2 ip link set dev veth-$ns_2 up

echo "Creating the bridge..."
sudo ip link add name br type bridge

echo "Adding the network namespaces interfaces to the bridge..."
sudo ip link set dev veth-$ns_1-br master br
sudo ip link set dev veth-$ns_2-br master br

echo "Assigning the IP address to the bridge..."
sudo ip addr add 172.16.0.1/24 dev br

echo "Enabling the bridge..."
sudo ip link set dev br up

echo "Enabling the interfaces connected to the bridge..."
sudo ip link set dev veth-$ns_1-br up
sudo ip link set dev veth-$ns_2-br up

echo "Setting the loopback interfaces in the network namespaces..."
sudo ip netns exec $ns_1 ip link set lo up
sudo ip netns exec $ns_2 ip link set lo up

echo "Setting the default route in the network namespaces..."
sudo ip netns exec $ns_1 ip route add default via 172.16.0.1 dev veth-$ns_1
sudo ip netns exec $ns_2 ip route add default via 172.16.0.1 dev veth-$ns_2


echo "Setting the route on the node to reach the network namespaces on the other node..."
sudo ip route add 172.16.1.0 via 192.168.0.5 dev eth0

echo "Enables IP forwarding on the node..."
sudo sysctl -w net.ipv4.ip_forward=1
