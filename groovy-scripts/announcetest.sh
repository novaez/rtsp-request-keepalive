#!/usr/bin/env groovy

// The path of the jar ball which includes S6ErmServer. 
// Note that put the lib directory of that jar ball into
// the same directory where the jar ball exists.
def rootPathErm = "../../artefact/srm-emus/target"

// The path of rtsp-request-keepalive. 
def rootPathRtspRequest = ".."
// The path of requests file, which will be processed by 
// the rtsp-request-keepalive. 
def pathRequests = "../requests-sample"

// Finds the first key in rtsp-request output,
// and retrieves its value, which starts from
// key, to the end specified.
def getValue(strBuff, key, end) {
    def string = strBuff.toString()
    def index = string.indexOf(key)
    if (index >= 0) {
        def start = index + key.length()
        def stop = string.indexOf(end, start)
        def value = string.substring(start, stop)
        return value
    }
    return ""
}

// Run S6Erm and wait for GET_PARAMETER from SRM.
// For simplicity, will not check response for the
// GET_PARAMETER, assuming ERM always retruns 200.
println "Starting ERM..."
def outErm = new StringBuffer()
def errErm = new StringBuffer()
def procErm = "java -cp $rootPathErm/srm-emus-1.0STD0-SNAPSHOT.jar:$rootPathErm/lib/* com.nagra.multiscreen.srm.emu.s6erm.S6ErmServer 5540 0".execute()
procErm.consumeProcessOutput(outErm, errErm)
println "  >> Waiting for connecting from SRM..."
while (1) {
    if (errErm) {
        println '  >> ERM failed: ' + errErm
        System.exit(1)
    }
    if (outErm) {
        //println 'ERM out: ' + outErm
        def url = getValue(outErm, "GET_PARAMETER ", " ")
        if (url != "") {
            println "  >> Connected with SRM." 
            break
        }
    }
}

println "Waiting for SRM connecting to all of back devices..."
sleep(1000 * 2)

// Run rtsp-request-keepalive, which will send SETUP
// to SRM. If the status code of response is 200, 
// retrieve OnDemandSessionId from error stream, 
// where rtsp-request output debug messages.
println "Starting rtsp-request-keepalive..."
def outRtspRequest = new StringBuffer()
def errRtspRequest = new StringBuffer()
def procRtspRequest = "$rootPathRtspRequest/rtsp-request-keepalive $pathRequests".execute()
println "  >> Reading requests from $pathRequests"
println "  >> Sending SETUP..."
procRtspRequest.consumeProcessOutput(outRtspRequest, errRtspRequest)
def ondemandid
while (1) {
    if (errRtspRequest) {
        def statusCode = getValue(errRtspRequest, "read: RTSP/1.0 ", " ")
        // Though 200 has been found, it is possible that can not to
        // find OnDemandSeesionId, because it has not been put in buffer.
        // We can find it in following cycles.
        if (statusCode != "" && statusCode != "200") {
            println "  >> Setup failed, status code is $statusCode"
            break 
        }
        ondemandid = getValue(errRtspRequest, "OnDemandSessionId: ", "..")
        if (ondemandid != "") {
            println "  >> Got OnDemandSeesionId: $ondemandid"
            break
        }
    }
}

// SRM sends ANNOUNCE only after it has received PINGs from box.
println "  >> Waiting for rtsp-request-keepalive sending PINGs."
sleep(1000 * 10)

// Make ERM send ANNOUNCE to SRM.
if (ondemandid != null && ondemandid != "") {
    println "Sending ANNOUNCE (OnDemandSessionId=$ondemandid) from ERM..."
    procErm.withWriter { writer ->
        writer << "$ondemandid"
    }
}

println "  >> Waiting for ANNCOUNCE from SRM..." 
println "Stopping rtsp-request-keepalive..." 
procRtspRequest.waitForOrKill(1000 * 10)
//println "rtsp-request-keepalive out: " + outRtspRequest
//println "rtsp-request-keepalive err: " + errRtspRequest

// Check whether rtsp-request-keepalive has got ANNOUNCE
def gotAnnounce = getValue(errRtspRequest, "read: ANNOUNCE ", "..")
if (gotAnnounce != "") {
    println "  >> Got ANNOUNCE. :-)"
} else {
    println "  >> Not got ANNOUNCE. :-("
}

//println "ERM out: " + outErm
//println "ERM err: " + errErm
println "Stopping ERM..." 
procErm.waitForOrKill(100)

System.exit(0)
