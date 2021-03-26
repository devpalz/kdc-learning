#!/bin/sh

set -e

# This is typically the uppercase of your domain - it is the 'realm' that kerberos has permission over.
if [ -z "${KRB5_REALM}" ]; then
    echo "Please provide a KRB5_REALM!"
    exit 1
fi

# This will map through the the 'kdc' entry of the krb5.conf file - Here, we point to the host that
# Is running our KDC ticketing service.
if [ -z "${KRB5_KDC_HOST_DNS}" ]; then
    echo "Please provide a KRB5_KDC_HOST_DNS"
    exit 1
fi

if [ -z "${KRB5_PASS}" ]; then
    echo "No Password for kdb provided; Creating one now."
    KRB5_PASS=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c"${1:-32}";echo;)
    echo "Using Password ${KRB5_PASS}"
fi

if [ -z "${KRB5_ADMINSERVER}" ]; then
    echo "No KRB5_ADMINSERVER provided; Using ${KRB5_KDC_HOST_DNS} instead."
    KRB5_ADMINSERVER=${KRB5_KDC_HOST_DNS}
fi

export KRB5_KDC_HOST_DNS KRB5_REALM KRB5_ADMINSERVER KRB5_PASS

# Set up the krb5 configuration
FILE=/config/krb5.conf
if [ -f "$FILE" ]; then
    echo "$FILE exists - Creating symlink"
else
  echo "Custom krb5.conf not provided, creating you a default!"
  envsubst < "/tmp/default.krb5.conf" > "/etc/krb5.conf"
fi

# Set up the supplementary configuration for a kerberos server
FILE=/config/kdc.conf
if [ -f "$FILE" ]; then
    echo "$FILE exists - Creating symlink"
else
  echo "Custom krb5.conf not provided, creating you a default!"
  envsubst < "/tmp/default.kdc.conf" > "/var/lib/krb5kdc/kdc.conf"
fi


# The acl file controls access to the Kerberos Database
echo "Creating default policy - Admin access to */admin"
echo "*/admin@${KRB5_REALM} *" > /var/lib/krb5kdc/kadm5.acl

# Now create the Kerberos Database
kdb5_util create -r "${KRB5_REALM}" -P "${KRB5_PASS}"

# Create the kerberos admin user
kadmin.local -q "addprinc -pw ${KRB5_PASS} admin/admin@${KRB5_REALM}"

# Create a keytab for the admin

# Run any scripts that are in the /scripts directory
for script in script/*.sh; do  # or wget-*.sh instead of *.sh
  if ! sh "$script" -H; then exit 1; fi
done

unset KRB5_REALM KRB5_KDC KRB5_PASS KRB5_ADMINSERVER

tail -f -n 100 /var/log/kadmin.log
