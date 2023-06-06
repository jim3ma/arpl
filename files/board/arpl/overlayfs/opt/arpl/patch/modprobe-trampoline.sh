#!/usr/bin/sh

# modprobe trampoline for SA6400, kernel 5.10.55

# This script is saved to /sbin/modprobe which is a so called UMH (user-mode-helper) for kmod (kernel/kmod.c)
# The kmod subsystem in the kernel is used to load modules from kernel. We exploit it a bit to load RP as soon as
# possible (which turns out to be via init/main.c => start_kernel()->rest_init()->kernel_init()->kernel_init_freeable()->do_basic_setup()->do_initcalls() => late_initcall(load_system_certificate_list) => load_certificate_list => ... => crypto_larval_lookup => request_module("crypto-pkcs1pad(rsa,sha384)")
# When the kernel of SA6400 is booted it will attempt to load a module "crypto-pkcs1pad(rsa,sha384)"... and the rest
# should be obvious from the code below. DO NOT print anything here (kernel doesn't attach STDOUT)

echo modprobe "$@" >> /var/log/modprobe.log

for arg in "$@"
do
  match=$(echo "$arg" | grep -oE '^crypto-')
  if [ "$match" = "crypto-" ]; then
    insmod /usr/lib/modules/rp.ko
    rm /usr/lib/modules/rp.ko
    rm /usr/sbin/modprobe
    ln -s /usr/bin/kmod /usr/sbin/modprobe
  fi
done

/usr/local/sbin/modprobe "$@"
