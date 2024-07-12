package io.goharbor

// the settings for test cases
public class CaseSettings implements Serializable{
    public String repository // the repository of test cases
    public String branch // the branch/tag of the test case repository
    public String cases // the test cases[database/ldap/oidc/uaa/trivy/notary/chartmuseum] which run against the Harbor instance. Split multiple items by comma
    public String imageRegistry // the registry where stores the test images, default: registry.goharbor.io
    public String imageRepositoryPrefix // the prefix of the repository where stores the test images, default: harbor-ci
    public String dockerHubUsername
    public String dockerHubPassword
    public String ecrAccessID // the access key ID of ECR for replication test
    public String ecrAccessSecret // the access key secret of ECR for replication test
    public String gitlabAccessID // the access key ID of Gitlab registry for replication test
    public String gitlabAccessSecret // the access key secret of Gitlab registry for replication test
    public String gcrAccessSecret // the access key secret of GCR for replication test
}