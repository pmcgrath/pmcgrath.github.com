---
layout: post
title: Running a simple dotnet Core Linux daemon
categories: dotnetcore
---

## Purpose
Someone has asked me about running a dotnet Core service as a Linux daemon, this is a very trivial example

Running a ASP.NET service should be much the same, as all project types result in console applications, so the generated project's main method will include a blocking call on host.Run()



## Environment
- Ubuntu 16.04 using [SystemD](https://www.freedesktop.org/wiki/Software/systemd/)
- dotnet [Core](https://www.microsoft.com/net/download/linux) 1.1



## Create application
This is just a simple console application that writes a message to stdout

```
# Create application
mkdir dnsvc
cd dnsvc
dotnet new console

# Change Program.cs
cat > Program.cs <<EOF
using System;
using System.Threading;


namespace dnsvc
{
  class Program
  {
    static void Main(
      string[] args)
    {
      var sleep = 3000;
      if (args.Length > 0) { int.TryParse(args[0], out sleep); }
      while (true)
      {
        Console.WriteLine($"Working, pausing for {sleep}ms");
        Thread.Sleep(sleep);
      }
    }
  }
}
EOF

# Restore dependencies
dotnet restore

# Publish to a local bin sub directory
dotnet publish --configuration Release --output bin

# Run local to verify all is good
dotnet ./bin/dnsvc.dll
```



## Create SystemD service file 
Will run the application from the bin sub directory for now

```
cat > dnsvc.service <<EOF
[Unit]
Description=Demo service
After=network.target

[Service]
ExecStart=/usr/bin/dotnet $(pwd)/bin/dnsvc.dll 5000
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```



## Configure SystemD so it is aware of the new service
```
# Copy service file to a System location
sudo cp dnsvc.service /lib/systemd/system

# Reload SystemD and enable the service, so it will restart on reboots
sudo systemctl daemon-reload 
sudo systemctl enable dnsvc

# Start service
sudo systemctl start dnsvc 

# View service status
systemctl status dnsvc
```



### Tail the service log
Since we are just writing to stdout the output can be examined with [journalctl](https://www.freedesktop.org/software/systemd/man/journalctl.html)

```
journalctl --unit dnsvc --follow
```



## Stopping and restarting the service
```
# Stop service
sudo systemctl stop dnsvc 
systemctl status dnsvc 

# Restart the service
sudo systemctl start dnsvc 
systemctl status dnsvc
```



# Cleaning up
```
# Ensure service is stopped
sudo systemctl stop dnsvc 

# Disable
sudo systemctl disable dnsvc 

# Remove and reload SystemD
sudo rm dnsvc.service /lib/systemd/system/dnsvc.service 
sudo systemctl daemon-reload 

# Verify SystemD is no longer aware of the service - Empty is what we want here
systemctl --type service |& grep dnsvc 
```



## Gracefull shutdown - Handling signals
- The service should handle [signals](https://en.wikipedia.org/wiki/Unix_signal) like SIGTERM, SIGINT etc.
- Would use this to do any cleanup just before exiting, like docker [stop](https://docs.docker.com/engine/reference/commandline/stop/) for containers
- Current version of dotnet Core does NOT handle this as far as I know
- You can follow this [issue](https://github.com/dotnet/coreclr/pull/4309), should hopefully be sorted in the near future
