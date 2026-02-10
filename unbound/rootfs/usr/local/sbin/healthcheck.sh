#!/bin/sh
# Adapted from Madnuttah's healthcheck (https://github.com/madnuttah/unbound-docker/blob/main/unbound/root/healthcheck.sh)
### Environment variables
HEALTHCHECK_PORT=${HEALTHCHECK_PORT:-5335}
EXTENDED_HEALTHCHECK_DOMAIN=${EXTENDED_HEALTHCHECK_DOMAIN:-nlnetlabs.nl}

# Check for opened tcp/udp port(s) with netstat, grep port count and save
# the result into a variable
check_port="$(netstat -ln | grep -c ":$HEALTHCHECK_PORT")" &> /dev/null

# If opened port count is equal 0 exit ungracefully
if [ $check_port -eq 0 ]; then
  echo "⚠️ Port $HEALTHCHECK_PORT not open"
  exit 1
else
  # Check if localhost can be query for a domain/host and save result
  ip="$(drill -Q -p $HEALTHCHECK_PORT $EXTENDED_HEALTHCHECK_DOMAIN @127.0.0.1)" &> /dev/null

  # Check the errorlevel of the last command, if not equal 0 exit ungracefully
  if [ $? -ne 0 ]; then
    echo "⚠️ Domain '$EXTENDED_HEALTHCHECK_DOMAIN' not resolved"
    exit 1 
  else
    echo "✅️ Domain '$EXTENDED_HEALTHCHECK_DOMAIN' resolved to '$ip':'$HEALTHCHECK_PORT'"
    exit 0
  fi
fi