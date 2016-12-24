stunnel-openshift
=================

This repository includes everything needed to build a stunnel Docker container 
that works in OpenShift. Stunnel allows you to create a SSL/TLS encrypted 
tunnel for arbitrary TCP traffic, making it an easy way to add transport 
security for older TCP protocols.

An additional benefit with OpenShift is that stunnel supports Server Name 
Indication (SNI), which means that it can tunnel arbitrary TCP traffic through
the OpenShift Router on port 443, without any setup of additional firewall or
load balancing rules like needed for Node Ports and Ingress IPs.

Example
-------

This project includes an OpenShift template in the file `stunnel-example.yml`.
The example deploys a pod with two containers. One container is a very simple
TCP service that echos back any traffic it is sent. The second container is 
stunnel, which listens for tunneled traffic and forwards it to our TCP service.

To start up the demo, download the template, then run the following from the 
command line (with a logged in `oc` client and in a project of your choice):

```
oc process -f stunnel-example.yml | oc create -f -
echo "After deployment, the stunnel example will be available at `oc get route stunnel --template '{{.spec.host}}'`:443"
```

The template sets up the server side of stunnel, but to talk to it we will 
needed a local client as well. Install stunnel locally (check your package 
manager, or https://www.stunnel.org/downloads.html). Next you need a 
configuration file that tells the client the other end of the tunnel. Here is 
my file `stunnel-client.conf`:

```
client=yes
sslVersion = TLSv1.2
foreground = yes
pid = 

[service]
accept=5002
connect=stunnel-demo.rhel-cdk.10.1.2.2.xip.io:443
verify=0
```

This configuration tells stunnel to act as a client, to listen locally on port 
`5002`, to forward all traffic received on that port to 
`stunnel-demo.rhel-cdk.10.1.2.2.xip.io:443` (replace with your stunnel route), 
and for this demo turns off validation of the server's cert since we are 
generating a self-signed cert for this example. In a real-world scenario you 
would want to use a trusted cert and set verify to a non-zero value.

You can now start stunnel: `stunnel stunnel-client.conf`

Now anyone who wants to connect to our TCP service in OpenShift can instead 
connect to port 5002 on the host running the stunnel client, and stunnel will
encrypt and forward all traffic into OpenShift.

We can now try it out. You'll need to have either telnet or socat installed. 
With telnet, run `telnet localhost 5002`. With socat, run 
`socat - TCP:localhost:5002`. Either way, you are now connected to our echo 
server in OpenShift via an encrypted tunnel. Type any message and press enter
to have the message echoed back to you.

Key takeaways:

1. Arbitrary TCP traffic was encrypted and forwarded into OpenShift
2. Server and Client applications required no configuration outside of host and
   port to connect to
   
Usage
-----

By default, the stunnel container will listen on port 5000, forward traffic to 
port 5001, and generate a self-signed cert on startup. You can override this 
behavior:

* Set the `CONNECT_PORT` environment variable to have stunnel forward to either 
  another port ("8080") or to another host and port ("my-service:8080")
* Mount a secret that contains two files/keys: "cert.pem" should have the 
  certificate chain to present to the client, and "key.pem" the key used to
  sign the certificate.