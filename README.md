# Docker-VPN

Needed a VPN for some hobby projects, so here yuh go.

---

## Setup

I use TorGuard for my Provider, so some of this may be applicable to others, or not.

There are a couple ways you can obtain the `.conf` file for openvpn.

- **Option 1**: Go to https://torguard.net/tgconf.php?action=vpn-openvpnconfig where you can build out your own custom config. Once you have the file, create a `config` folder at the root of this repo and drop the new file in there.
- **Option 2**: Run `./conf.sh`. It'll go get the latest `.ovpn` files, unpack the files, and build out the config in the appropriate location. There's a section at the top of the script with a `files` Array. You can update that to configure what locations you want to have in the VPN.

---

## Run

```sh
docker-compose up

# Print the IP
docker-compose exec vpn curl ifconfig.co
```

You can then use the VPN for another Container using something like this:

```yml
version: "3.4"

services:
  service-name:
    image: fake/image-name
    network_mode: container:vpn
    # NOTE - If you're using a VPN, it has to expose the ports in it's Service.
    # If you're not using a VPN, uncomment the below `ports` section.
    # ports:
    #   - "3000:3000"

```
Note that `container:vpn` is the actual value for `network_mode`. It tells Docker that this Container wants to use the `vpn` Container's network connection.

---

## Troubleshooting

These issues had some helpful info:
- https://github.com/dperson/openvpn-client/issues/238
- https://github.com/dperson/openvpn-client/issues/211
