# Log Shipping to Event Hub with rsyslog


## Event Hub

Deploy an Event Hub and configure two Shared Access Policies at the namespace (root) level:

| Name | Claims |
|---|---|
| RootListenPolicy | Listen |
| RootSendPolicy | Send |

The connection strings for these policies will be used later in the confiugration.

Next, create an Event Hub named: `vmlogs`

## Log Processor



## Log Collector

Deploy a virtual machine running Ubuntu 18.04 LTS or higher. Connect to the server over SSH and clone this repo to your user's home directory. Ensure Python 3 is installed:

```bash
sudo apt update
sudo apt install python3 && audo apt install python3-pip
```

Install script dependencies for Event Hub:

```bash
sudo -H pip3 install azure-eventhub
```

 Run the following script to deploy `eventhub.py` and `41-az_eventhub.conf`.

```bash
# deploy the Event Hub forwrding script and configure permissions
sudo mkdir /share
sudo cp vm-log-shipping/forwarder-py/eventhub.py /share
sudo chmod u+x /share/eventhub.py
sudo chown -R syslog /share

# Copy rsyslog configuration for omprog
sudo cp vm-log-shipping/scripts/41-az_eventhub.conf /etc/rsyslog.d/42-az_eventhub.conf
```

Add the connection string for your Event Hub **RootSendPolicy** to `/share/eventhub.py`:

```python
def onInit():
    global producer
    producer = EventHubProducerClient.from_connection_string(conn_str="", eventhub_name="vmlogs")
```

Configure rsyslog to accept inbound TCP and UDP traffic from log forwarders by un-commenting the following lines in `/etc/rsyslog.conf`:

```bash
# provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

# provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 50514
```

Ensure these ports are open for inbound traffic on all Network Security Groups (NSGs) associated to this virutal machine.

> NOTE: Secure configuration of log forwarding is out-of-scope for this sample. In a production environment, you will need to configure SSL for rsyslog and define granular network filtering rules.

Restart rsyslog: `sudo service rsyslog restart`

Generate a test log and confirm a message is submitted to Event Hub:

```bash
logger -p user.info test message
```

## Application Server

Use the following commands to install nginx:

```bash
sudo apt update && sudo install nginx
```

Grant read access to the access log:

```bash
sudo chmod -R ugo+rx /var/log/nginx/access.log
```

Open up port 80 on the inbound NSG rule for the virtual machine and confirm you can access the nginx home screen using the VM's IP address.  Next, confirm the `omsagent` can read the log file:

```bash
sudo su omsagent -c 'cat /var/log/nginx/access.log'
```