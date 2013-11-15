#!/usr/bin/env groovy

def cli = new CliBuilder(usage:'perannouncetest')
 cli.h(longOpt:'host', args:1, argName:'host', 'SRM Server IP Address')
 cli.p(longOpt:'port', args:1, argName:'port', 'SRM Server Port')
 cli.t(longOpt:'timeout', args:1, argName:'timeout', 'Timeout')
 cli.n(longOpt:'number', args:1, argName:'number', 'rtsp-request Process Number')

def options = cli.parse(args)

//println cli.usage()
def host = "${options.host}:${options.port}"
def timeout = options.timeout.toInteger()

def procs = [:]
def souts = [:]
def serrs = [:]
for (int i = 0; i < options.number.toInteger(); i++)
{
    println "Start process $i..."

    def pt = i + 1
    def str = """\
# after, interval, count, args
0, 0, 0, -d -p -b -m SETUP rtsp://${host}/;purchaseToken=${pt};serverID=localhost Require=com.comcast.ngod.s1 Transport=MP2T/DVBC/QAM;unicast;client=20001;qam_name=Gobelins-0.0 ClientSessionId=007
5, 6, *, -d -p -b -m PING rtsp://${host}/ Require=com.comcast.ngod.s1 OnDemandSessionId= Session="""

    def p1 = [
        "echo",
        "$str",
    ].execute()
    
    def p2 = [
        "../rtsp-request-keepalive",
    ].execute()

    def sout = new StringBuffer()
    def serr = new StringBuffer()
    p2.consumeProcessOutput(sout, serr)

    def procname = "proc_${i}"
    procs[procname] = p2
    souts[procname] = sout
    serrs[procname] = serr
    
    p1 | p2
}

println "Sleeping for ${timeout}..."
sleep(timeout)
procs.each{ k, v -> v.waitForOrKill(1) }
souts.each{ k, v -> println v }
serrs.each{ k, v -> println v }
