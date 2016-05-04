# cryptstick

**cryptstick** is a small utility which provides a convinient interface to mount encrypted luks container and unmount unused container automatically after a certain amount of time.

## Idea

If you would like to store sensitive data like your private keys more securely you will often use a veracrypt container or a luks container. You mount it once, you use the private key then and usually you forget to unmount and close the container. Your private data might be open to attacks. **cryptstick** should protect you from dealing with unnecessarily mounted sensitive data.

## How to use?

```bash
# Firstly, create a luks container using create.sh. You do this once.
./create.sh my-container 1024M mkfs.ext4

# Secondly, mount it using mount.sh
./mount.sh my-container
```

`mount.sh` also has a xterm frontend if you open it by clicking it for example.

## Configuration

You can store your own configuration in `cs-settings.conf`.

## Tips

* You can combine cryptstick with a USB drive. Plug it in when you need it. Unplug it afterwards.
* You can store your private data like private keys, passwords or certificates inside an encrypted container. Use them only if you really need them. **cryptstick** will help you to protect you from stealing this data when you don’t need them.
* Take a look at `mount.sh`. It has some options to tune if you want.
* After the initial use time it checks regularily for opened files. It bells once and prints the processes using the files.
* You can CTRL+C the wait loop. It will force-kill any accessing process.
