package io.goharbor

// the FreshInstallPipelineExecutor defines the customized steps which caller can implement
abstract class FreshInstallPipelineExecutor {
    void preInstall(){
        // do nothing
    }
    abstract HarborInstance install()
    void postInstall(){
        // do nothing
    }
    void preTest(){
        // do nothing
    }
    void postTest(){
        // do nothing
    }
}
