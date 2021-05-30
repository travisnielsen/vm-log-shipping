# Log Shipping to Event Hub

## Deployment

### Event Hub SAS token

https://docs.microsoft.com/en-us/rest/api/eventhub/generate-sas-token#powershell


## Virtual Machine Configuration

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