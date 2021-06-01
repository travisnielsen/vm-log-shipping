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

The Log Processor is implemented at a .NET 5 Event Trigger Function. To run this locally for testing, ensure you have the latest version of the [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local?tabs=windows%2Ccsharp%2Cbash) installed. You will also need to ensure the [Azurite extension for Visual Studio Code](https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azurite#install-and-run-the-azurite-visual-studio-code-extension) is installed to support locally hosting the Functions runtime.

In the `processor` directory, add a configuration entry for *EventHubConnectionString* in `local.settings.json` and set the value to the connection string of the **RootSendPolicy** set on your Event Hub.

```json
{
    "IsEncrypted": false,
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
        "EventHubConnectionString": "[YOUR_ROOTSENDPOLICY_CONNECTION_STRING"
    }
}
```

To test connectivity and view any log entries submitted through Event Hub, start the Azurite Blob servcie, associate it to the `processor` workspace item, and use the **Attach to .NET Functions (processor)** function in the VS Code debugger to start the Function. Once the Log Collector is configured and events are submitted, you should see messages printed to the console output.

## Log Collector

Deploy a virtual machine running Ubuntu 18.04 LTS or higher. Connect to the server over SSH and clone this repo to your user's home directory. Ensure that Node JS 14.x is installed by running the following commands from your home directory.

```bash
sudo apt update
sudo apt install curl
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
```

Install script dependencies for Event Hub:

```bash
sudo -H pip3 install azure-eventhub
```

 Run the following script to deploy `forwarder.js` and `41-az_eventhub.conf`.

```bash
# deploy the Event Hub forwrding script and configure permissions
sudo mkdir /share
sudo cp vm-log-shipping/forwarder-js/forwarder.js /share
sudo chmod u+x /share/forwarder.js
sudo chown -R syslog /share

# Copy rsyslog configuration for omprog
sudo cp vm-log-shipping/scripts/41-az_eventhub.conf /etc/rsyslog.d/42-az_eventhub.conf
```

Add the connection string for your Event Hub **RootSendPolicy** to `/share/forwarder.js`:

```javascript
const connectionString = "";
```

Finally, install NPM modules to the `/share` directory:

```bash
cd /share
npm install @azure/event-hubs
npm install readline
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

Confirm you can access the default NGINX home page over port 80 on the virtual machine. Next, open `/etc/rsyslog.conf` and configure rsyslog to forward logs to the collection server IP address over TCP.

```bash
# Send logs to the remove syslog server over TCP
*.* @@[your_ip]:50514
```

Create an rsyslog configuration file NGINX:

```bash
sudo touch /etc/rsyslog.d/41-nginx.conf
```

Modify the file contents with the following:

```bash
module(load="imfile") # Load the imfile input module
input(type="imfile" File="/var/log/nginx/access.log" Tag="nginx:")
```

Restart rsyslog to apply the changes: `sudo service rsyslog restart`
