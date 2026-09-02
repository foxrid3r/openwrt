# Provision Router

The custom image provides the `provision-router` tool which should be used to interactively changes the deployment-specific settings of a newly flashed router.

```sh
provision-router
```

It prompts for the hostname, root password, LAN network, DHCP configuration, machine Wi-Fi, and isolated NTP uplink. Run it as `root` after installing the custom image.

The complete prompt-by-prompt instructions are in [Router Provisioning](../getting-started/provisioning.md).
