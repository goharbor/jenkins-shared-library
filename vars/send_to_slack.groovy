// send test result to slack
def call(String channel, token, teamDomain){
    slackSend(channel: channel,
        token: token,
        teamDomain: teamDomain,
        color: currentBuild.currentResult == "SUCCESS" ? "good" : "danger",
        message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME}#${env.BUILD_NUMBER}, takes ${currentBuild.durationString.replace(' and counting', '')}\n More info at: ${env.BUILD_URL}")
}