// publish robot test case result
def call(String path){
    robot outputPath : path, otherFiles : "**/*.png", unstableThreshold: 100, passThreshold: 100
}