package io.goharbor

// the settings for fresh install pipeline
public class FreshInstallPipelineSettings implements Serializable{
    // The node where the pipeline runs on. Refer to https://www.jenkins.io/doc/pipeline/steps/workflow-durable-task-step/#node-allocate-node for the format
    String node;
    /*
    A closure to set the pipeline properties.
    Refer to https://www.jenkins.io/doc/pipeline/steps/workflow-multibranch/#properties-set-job-properties for all properties.
    e.g.
    1) Set parameter and lot rotate:
        properties = {
            return [
                parameters([
                    string(name: 'branch', defaultValue: 'master', description: 'The branch/tag to run for'),
                    choice(name: "cluster", choices: ["cluster01", "cluster02"], description: 'The Kubernetes cluster that the Harbor is deployed on')
                ]),
                buildDiscarder(strategy: logRotator(numToKeepStr: "6"))
            ]
        }
    2) Set parameter dynamically:
        properties = {
            def names = []
            withCredentials([file(credentialsId: "kubeconfig", variable: "KUBE_CONFIG_FILE_PATH")]) {
                def kubeConfig = readYaml file: env.KUBE_CONFIG_FILE_PATH
                kubeConfig.contexts.each {
                    names.add(it.name)
                }
            }
            return [
                parameters([
                    string(name: 'branch', defaultValue: 'master', description: 'The branch/tag to run for'),
                    choice(name: "cluster", choices: names, description: 'The Kubernetes cluster that the Harbor is deployed on')
                ])
            ]
        }
    */
    Closure properties;
    public FreshInstallPipelineExecutor executor;
    // The closure returns an instance of io.goharbor.CaseSettings. Use the closure instead of a class directly to be able to
    // call the Jenkins steps which must be included inside the "node" block
    Closure caseSettings;
}