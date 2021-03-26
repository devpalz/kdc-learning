#!/bin/sh

set -e

echo "Running seed script"

# Create a policy for users
kadmin.local -q "addpol users"

# Create a user, with no password
kadmin.local -q "addprinc -randkey -policy users healthcheckuser"


# add_entry -password -p vemkd/cluster1@ibm.com -k 1 -e aes256-cts
