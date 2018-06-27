# OpenVPN in a container

This setup splits responsibilities between the OpenVPN server, and the configuration generation -container. It gives you the ability to generate certificates etc. on one machine that you can keep locally without ever exposing to the internet, and deploy only the necessary parts on a container with the OpenVPN server.

Based on Alpine Linux, and thus has a minimal footprint. The server doesn't even know how to generate new client certificates for you, so it should be pretty safe to deploy the server pretty much anywhere.

You store the private keys and client certificates etc. only locally, so there's little risk in you accidentally leaving them to the server.


## Why would you want to use this?

If you're seriously asking this question, you probably don't. Buy F-Secure Freedome, ExpressVPN, PureVPN, or any of the other VPN services.


## Initial configuration

You will likely want to open up `config/client.conf` in an editor and change the `ovpn.example.com` to a domain you intend to use. If you don't know what it is yet or plan to use an IP, you can leave it and change it after deploying the server.

Just remember to rebuild the config container after the change, before trying to generate new client configs or you'll have to fix them up manually later.

*Private key infrastructure*

Build the configuration container and start it up

```
cd config
docker build -t ovpn-config .
docker run -it ovpn-config /bin/sh
```

For the first time, you should initialize your `easyrsa`. BE SURE NOT TO RUN THIS AGAIN LATER, AS IT WILL WIPE YOUR CONFIGURATION!

Run in the container shell we just started:

```
./easyrsa init-pki
./easyrsa build-ca
./easyrsa gen-dh
./easyrsa gen-crl
openvpn --genkey --secret pki/ta.key

# You can replace "Server" with another name, but you have to update openvpn.conf and package-server.sh
./easyrsa gen-req Server nopass
./easyrsa sign-req server Server

./package-server.sh
```

Now you want to copy the generated contents back to your host, open another shell on your host, and in the `config` -folder run:

```
# Find the Container ID for your running ovpn-config machine
docker container ls
docker cp <id>:/etc/openvpn/pki .         # Backup the private keys
docker cp <id>:/etc/openvpn/server.tgz .  # Server config
```

DO NOT ADD THESE FILES TO VERSION CONTROL, SAVE THEM SECURELY SOMEWHERE ELSE!

Use e.g. [7-Zip](https://www.7-zip.org/download.html) encrypted archives stored on a cloud drive (DropBox, Google Drive, OneDrive, ...), or some zero-knowledge encrypted cloud drive (like SpiderOak).

If you lose your config container all you have to do is restore this folder and make a new build.


## Adding clients

If still running in the first-time session, you don't need to do anything special, unless you didn't edit `config/client.conf` and don't want to edit generated client configurations manually later.

However, for the next sessions make sure you copied the `pki` folder above, and rebuild the image with `docker build -t ovpn-config .` and then run it again with `docker run -it ovpn-config /bin/sh`. Otherwise the required PKI files are not available and you cannot generate new certificates.

Now generate certificates for each of your clients (each client device should have their own certificates), in the `ovpn-config` image run:

```
./gen-client.sh <client-name>  # E.g. Bob-Desktop, Bob-Phone, ...
```

Then to copy the generated configuration, again on the host in the `config` -folder run the commands `gen-client.sh` printed out at the end. They should look something like:

```
docker cp <id>:/etc/openvpn/<client-name>.ovpn .  # Client config
```

As soon as you disconnect the shell from the Docker guest, the container will be deleted, so be sure you copy the configuration before you do that.

Now move the `*.ovpn` files securely to your client device, and don't keep them lying around. E.g. on Windows you copy the files to `C:\Program Files\OpenVPN\config` for the OpenVPN GUI to find them.

*Random tip of the day:* Don't reuse the client configurations, OpenVPN will likely just boot off one of the clients if multiple are connected with the same client certificate giving you headaches.


## Building the server image

REMEMBER: You will need to build a new version of the server when you need to update the configuration, so if you plan to do any of that edit `openvpn.conf` now. However, when creating new clients you don't have to deploy a new server.

In the repository root, run:

```
docker build -t ovpn .
```

You probably shouldn't publish this to a public docker registry even if it should be pretty safe, so make sure your docker is configured for the correct PRIVATE docker registry.

```
docker tag ovpn private.docker.registry/path/ovpn
docker push private.docker.registry/path/ovpn
```

## Running the server

The server is going to need the Docker capabilities `NET_ADMIN` and `NET_RAW`. If running directly via Docker you can add them via `--cap-add`, in Kubernetes you need something like this inside the specific `containers` -definition in your deployment:

```
securityContext:
  capabilities:
    add:
    - NET_ADMIN
    - NET_RAW
```

## Static external IP

If you need a static IP you can set up something like that via routing through a NAT instance in your Kubernetes hosting environment.

For an example of how to set one up, check out this guide
https://cloud.google.com/solutions/using-a-nat-gateway-with-kubernetes-engine


## License and legal

Anything and everything in this repository is under the MIT license. No promises it works, no guarantees none of your secrets get leaked, no warranty of any kind, you use it at your own risk, yadi yadi yada.

If you're going to use it, you should probably make sure you understand how it works and agree with the configuration instead of blindly using some VPN setup you found on the internet.
