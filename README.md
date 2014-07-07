# Nexus REST #

## Overview ##

This module provides a couple of types and providers to manage the configuration of
[Sonatype Nexus](http://nexus.sonatype.org/) via the exposed REST interface.

## Usage ##

First of all you need to create a configuration file `$confdir/nexus_rest.conf` (whereas `$confdir` defaults to
`/etc/puppet`):

```
#!yaml
---
# credentials of a user with administrative power
admin_username: admin
admin_password: secret

# the base url of the Nexus service to be managed
nexus_base_url: http://localhost:8081/

# Certain operations may result in data loss. The following parameter(s) control if Puppet should perform those
# changes or not. Set the parameter to `false` to prevent Puppet from enforcing the change and cause the Puppet run to
# fail instead.
can_delete_repositories: false

# timeout in seconds for opening the connection to the Nexus service
# connection_open_timeout: 10

# timeout in seconds for reading the answer from the Nexus service
# connection_timeout: 10

```

This file needs to exist on the machine where the Nexus is running. It will provide the module with the required
information about where Nexus is listening and which credentials to use to enforce the configuration. Obviously it is
recommended to manage the file within Puppet and limit the visibility to the root and / or the Puppet user.

If you have a running Nexus instance, you can just benifit from the fact that all resources are implemented as
providers: simply inspect the current state with

```
puppet resource <resource-name>
```

and copy&paste the result in your manifest.

### Global Configuration ###

The global configuration has been decomposed into different resources. The following examples show how to use them.

```
#!puppet
nexus_application_server_settings { 'current':
  baseurl  => 'http://example.com/',
  forceurl => false,
  timeout  => 60,
}
```

```
#!puppet
nexus_connection_settings { 'current':
  timeout             => 10,
  retries             => 3,
  query_string        => 'foo=bar&foo2=bar2',
  user_agent_fragment => 'foobar',
}
```

Note: the query string returned by Nexus contains encoded HTML entities. So submitting e.g. `&` via the REST interface
will result in an new version of the query string where it is replaced with `&amp;`. To avoid a ongoing war between
Nexus and Puppet updating the configuration, this module will unescape the received query string. Hence, this can be
subject to an API breakage when Sonatype would decide to change the behaviour.


```
#!puppet

nexus_system_notification { 'current':
  enabled => true,
  emails  => ['admins@example.com'],
  roles   => ['nx-admin'],
}
```

```
#!puppet
nexus_proxy_settings { 'current':
  http_proxy_enabled   => true,
  http_proxy_hostname  => 'example.com',
  http_proxy_port      => 8080,
  https_proxy_enabled  => true,
  https_proxy_hostname => 'ssl.example.com',
  https_proxy_port     => 8443,
  non_proxy_hostnames  => ['localhost', '*.example.com'],
}
```

Note: The current implementation doesn't support authentication at the proxy server. We're happy to accept a PR on this matter.

```
#!puppet

nexus_smtp_settings { 'current':
  hostname               => 'mail.example.com',
  port                   => 25,
  username               => 'jdoe',
  password               => present,
  password_value         => 'keepitsecret',
  communication_security => none,
  sender_email           => 'nexus@example.com',
}
```

### Repository Configuration ###

```
#!puppet

nexus_repository { 'new-repository'
  label                   => 'A New Repository',   #required
  provider_type           => 'maven2',             #valid values: 'maven1', 'maven2' (default), 'nuget', 'site', 'obr'
  type                    => 'hosted',             #valid values: 'hosted' (default), 'proxy', 'virtual'
  policy                  => 'snapshot',           #valid values: 'snapshot', 'release' (default), 'mixed'
  exposed                 => true,                 #valid values: true (default), false
  write_policy            => 'allow_write_once',   #valid values: 'read_only', 'allow_write_once (default)', 'allow_write'
  browseable              => true,                 #valid values: true (default), false
  indexable               => true,                 #valid values: true (default), false
  not_found_cache_ttl     => 1440,                 #1440 is default
  local_storage_url       => 'file:///some/path',  #valid values: not specified (default), or absolute file path beginning with 'file:///'
  download_remote_indexes => false                 #valid values: true, false (default)
}
```

```
#!puppet

nexus_group_repository { 'example-group-repo':
  label           => 'Example Group Repository',   #required
  provider_type   => 'maven2',                     #valid values: 'maven1', 'maven2' (default), 'nuget', 'site', 'obr'
  exposed         => true,                         #valid values: true (default), false
  repositories    => ['new-repository',            #note: these must be existing repositories with the same `provider_type` as the repository group, order is significant, [] is default
                      'other-repository',
                      'repository-3']
}
```

## Limitations ##

### Ruby and Puppet compatibility ###
The module has been tested to work with various Puppet and Ruby versions. Supported are

* Ruby 1.8.7
* Ruby 1.9.3
* Ruby 2.0.0

and

* Puppet 3.4
* Puppet 3.5

It is very likely to work with any Puppet 3.x version. Support for Puppet 2.7.x has been dropped in favour of
built-in functionality that is only available in Puppet 3.x.

### Nexus compatibility ###
Furthermore, the module has been tested with the following Nexus versions:

* Nexus Pro 2.7.2 running on Ubuntu 12.04

### A note on passwords ###

Due to the limitation of the Nexus REST api it is not possible to retrieve the current value of a password. Hence,
Puppet can only manage the existence of the Puppet but won't notice when passwords change. Either way, passwords will
be updated when attributes of the same resource change as well.

## Contributing ##

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
