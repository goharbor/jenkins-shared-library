package io.goharbor

// the information of the Harbor instance
public class HarborInstance implements Serializable{
    public String coreServiceURL
    public String notaryServiceURL
    public String adminPassword
    public String authMode
    public String components // the enabled components, split multiple items by comma
    public String hostIPMappings // the mapping of hostname and IP address. If the hostnames cannot be resolved by DNS server, add them into this map and the mappings will be added into the "/etc/hosts" file. Split multiple items by comma
    public String proxy // set the proxy to access the Harbor instance which is installed inside an internal network
    public String replicationTargetURL // the URL of another Harbor instance used for replication tests
}