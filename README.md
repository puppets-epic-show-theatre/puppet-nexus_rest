# Puppet Module for Sonatype Nexus #

## Overview ##

Puppet Module for Sonatype Nexus aims to offer native configuration of Nexus
instances in Puppet. The module uses Nexus' REST interface to manage configuration,
this method of managing Nexus instances has many advantages over other methods.

An alternative method of managing Nexus configuration is to modify xml files in the
`sonatype-work/nexus/conf` directory. This option has a few problems:

 * Need to restart Nexus to make sure new XML configuration files are processed
 * Ephemeral changes (staging repositories, for example) are lost after a Puppet run
 * Have to manage and maintain XML configuration templates and files
 * When Nexus changes XML configuration files, Puppet will overwrite them and restart Nexus

The other alternative is to use [Puppet Augeas](https://docs.puppetlabs.com/guides/augeas.html),
which allows more intelligent management of XML content, but this approach still shares several
disadvantages and has its own:

 * Need to restart Nexus to make sure new XML configuration files are processed
 * Have to manage and maintain XML configuration templates and files
 * Introduce additional complexity to Puppet manifests

This Puppet Module aims to address all of these disadvantages. At this point
not all options covered by XML configuration are covered by this module, but the module is
designed to be easily extensible and pull requests are welcome. This module could be
capable of managing anything configurable through the Nexus UI.

In a nutshell, Puppet Module for Sonatype Nexus allows configuration to go from this:

```
  #manifest/.../config.pp
  file { ".../sonatype-work/nexus/conf/nexus.xml":
    content => template('buildeng_nexus/common/opt/nexus/current/conf/nexus.properties.erb'),
    owner   => $buildeng_nexus::common::params::user,
    group   => $buildeng_nexus::common::params::group,
    notify  => Class['buildeng_nexus::common::service'],
  }
```

```
  #templates/.../sonatype-work/sonatype/conf/nexus.xml.erb
  ...
  <repositories>
    <repository>
      <id>public</id>
      <name>Public Repository</name>
      <providerRole>org.sonatype.nexus.proxy.repository.Repository</providerRole>
      <providerHint>maven2</providerHint>
      <localStatus>IN_SERVICE</localStatus>
      <userManaged>true</userManaged>
      <exposed>true</exposed>
      <browseable>true</browseable>
      <writePolicy>ALLOW_WRITE</writePolicy>
      <indexable>true</indexable>
      <searchable>true</searchable>
      <localStorage>
        <provider>file</provider>
        <url>.../sonatype-work/nexus/storage/public</url>
      </localStorage>
      <externalConfiguration>
        <repositoryPolicy>RELEASE</repositoryPolicy>
      </externalConfiguration>
    </repository>
    ...
  </repositories>
  ...
```


To this:

```
  #manifest/.../config.pp
  nexus_repository { 'public':
    label          => 'Public Repository',
    provider_type  => 'maven2',
    type           => 'hosted',
    policy         => 'release',
  }
```

## Requirements ##

The module doesn't have any dependencies on other Puppet modules. But it is using Ruby libraries that may not be
contained in the default installation. Currently, the following libraries are expected to be installed; the module won't
install or manage them in any way (see the Gemfile for more information):

* json
* rest-client
* mime-types

Depending on the version of Ruby you're using, some of them are shipped by default (e.g. `json`) whereas others need
to be installed via Puppet or in a bootstrap process like

```
package { 'rest-client':
  ensure   => installed,
  provider => gem,
}
```

Obviously it would be a great improvement if the module itself could provide a manifest to install and manage its
dependencies. Any contributions are welcome!

Limitation: at the moment the module doesn't handle the provision-from-scratch use case very well and will cause a
couple of warnings during the resource discovery phase as the Ruby gems may not be available. As long as the gems are
installed before the Puppet resources are used, everything should be fine.

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

# Number of retries before giving up on the health check and consider the service not running.
# health_check_retries: 50

# Timeout in seconds to wait between single health checks.
# health_check_timeout: 3
```

The configuration file will provide the module with the required information about where Nexus is listening and which credentials to use to enforce the configuration. Obviously it is
recommended to manage the file within Puppet and limit the visibility to the root.

Any change is enforced through Nexus' REST api. Hence, the Nexus service has to be running before any modification can
be made. In general, any ordering between the `service { 'nexus': }` resource and resources provided by this module
should be made explicit in the Puppet manifest itself. This module doesn't express any autorequire dependency ('soft
dependency') on the service resource itself - this is up to the user of the Puppet module. However, any resource provided by this module
will wait a certain amount of time in order to give Nexus the chance to properly start up. The default timeout is 150
seconds and can be configured via the configuration file.

All resources are implemented as providers. This means that if you have a running Nexus instance you can simply inspect the current state with:
```
puppet resource <resource-name>
```
for example:
```
puppet resource nexus_repository
```
and copy & paste the result into your manifest file.

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
Nexus and Puppet updating the configuration, this module will unescape the received query string. This can be subject to API breakages if Sonatype decides to change the behaviour.

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

Note: The current implementation doesn't support authentication at the proxy server. But code contributions are gratefully accepted!

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


## Crowd Settings ##
The Nexus Crowd Settings can be configured using the `nexus_crowd_settings` resource:

```
#!puppet

nexus_crowd_settings { 'current':
    application_name           => 'AppName',
    application_password       => 'present',                  #absent is default, valid values: absent, present
                                                              #if present, the application_password_value will be used
    application_password_value => 'AppPassword',
    crowd_server_url           => 'http://crowd-server.com',
    http_timeout               => 100                         #default is 60
}
```

## LDAP configuration ##

The Nexus LDAP settings can be configured using the `nexus_ldap_settings` resource:

```
#!puppet

nexus_ldap_settings { 'current':             #only define one of these resources
  description                   => 'repo1 read-write',   #optional
  hostname                      => 'somehost',           #required: LDAP server hostname
  port                          => '389'                 #389 is default
  username                      => 'someuser',           #required: User to authenticate with LDAP service
  password                      => 'present',            #absent is default, valid values: absent, present
                                                         #if present, the password_value will be used
  password_value                => 'hunter2',            #optional, default is unspecified
  protocol                      => 'ldap',               #ldap is default, valid values: ldap, ldaps
  authentication_scheme         => 'none',               #none is default, valid values: simple, none, DIGEST_MD5, CRAM_MD5
  search_base                   => '',                   #required
  realm                         => '',                   #optional
  ldap_filter                   => '',                   #optional
  email_address_attribute       => 'email',              #email is default
  user_password_attribute       => 'pw',                 #optional
  user_real_name_attribute      => 'displayName',        #default is displayName
  user_id_attribute             => 'cn',                 #cn is default
  user_object_class             => 'user',               #user is default
  user_base_dn                  => 'OU=users',           #OU=users is default
  user_subtree                  => false,                #false is default
  group_base_dn                 => 'OU=groups',          #OU=groups is default, required if ldap_groups_as_roles is true
  group_id_attribute            => 'cn',                 #cn is default, required if ldap_groups_as_roles is true
  group_member_attribute        => 'uniqueMember',       #uniqueMember is default, required if ldap_groups_as_roles is true
  group_member_format           => '${dn}',              #${dn} is default, required if ldap_groups_as_roles is true
  group_object_class            => 'group',              #group is default, required if ldap_groups_as_roles is true
  group_subtree                 => false,                #false is default
  ldap_groups_as_roles          => false,                #false is default
}
```



### Repository Configuration ###

```
#!puppet

nexus_repository { 'new-repository':
  label                   => 'A New Repository',   #required
  provider_type           => 'maven2',             #valid values: 'maven1', 'maven2' (default), 'nuget', 'site', 'obr', 'npm', 'rubygems'
  type                    => 'hosted',             #valid values: 'hosted' (default), 'proxy', 'virtual'
  policy                  => 'snapshot',           #valid values: 'snapshot', 'release' (default), 'mixed'
  exposed                 => true,                 #valid values: true (default), false
  write_policy            => 'allow_write_once',   #valid values: 'read_only', 'allow_write_once (default)', 'allow_write'
  browseable              => true,                 #valid values: true (default), false
  indexable               => true,                 #valid values: true (default), false
  not_found_cache_ttl     => 1440,                 #1440 is default (minutes, -1 is never)
  local_storage_url       => 'file:///some/path',  #valid values: not specified (default), or absolute file path beginning with 'file:///'

  #the following 'remote_' properties may only be used when type => 'proxy'

  remote_storage          => 'http://some-repo/',  #required
  remote_download_indexes => true,                 #valid values: true (default), false
  remote_auto_block       => true,                 #valid values: true (default), false
  remote_file_validation  => true,                 #valid values: true (default), false
  remote_checksum_policy  => 'warn',               #valid value : warn (default), ignore, strict_if_exists, strict
  remote_user             => 'some_user',          #optional, default is unspecified
  remote_password_ensure  => 'present',            #optional, valid values: absent, present
  remote_password         => 'hunter2',            #optional, default is unspecified
  remote_ntlm_host        => 'nt_host',            #optional, default is unspecified
  remote_ntlm_domain      => 'nt_domain',          #optional, default is unspecified
  remote_artifact_max_age => -1,                   #-1 is default (minutes, -1 is never)
  remote_metadata_max_age => 30,                   #default is 1440 (minutes, -1 is never)
  remote_item_max_age     => 60,                   #default is 1440 (minutes, -1 is never)
  remote_user_agent       => 'Nexus 2.9',          #optional, default is unspecified
  remote_query_string     => 'arg1=true&arg2=5'    #optional, default is unspecified
  remote_request_timeout  => 120,                  #60 is default (seconds)
  remote_request_retries  => 3,                    #10 is default
}
```

```
#!puppet

nexus_repository_group { 'example-repo-group':
  label           => 'Example Repository Group',   #required
  provider_type   => 'maven2',                     #valid values: 'maven1', 'maven2' (default), 'nuget', 'obr', 'npm', 'rubygems'
  exposed         => true,                         #valid values: true (default), false
  repositories    => [                             #note: these must be existing `nexus_repository` resources  with the same `provider_type` as the repository group, order is significant, [] is default
                      'new-repository',
                      'other-repository',
                      'repository-3'
                     ]
}
```

```
#!puppet

nexus_repository_target { 'dummy-target-id':
  label         => 'dummy-target',                 #required
  provider_type => 'maven2',                       #e.g. 'maven1', 'maven2' (default), 'nuget', 'site', 'obr' or 'any', 'npm', 'rubygems'
  patterns      => [                               #required, must be non-empty
                        '^/com/atlassian/.*$',
                        '^/io/atlassian/.*$'
                   ]
}
```

```
#!puppet

nexus_repository_route { 'example-repo-route':
  position          => '0',                        #required, first route should be '0', second '1', and so on
  url_pattern       => '.*/com/atlassian/.*',      #required
  rule_type         => 'inclusive',                #valid values: 'inclusive' (default), 'exclusive', 'blocking'
  repository_group  => 'example-repo-group',       #required, must be an existing `nexus_repository_group` resource
  repositories      => [                           #required if `rule_type` is not 'blocking', these must be existing `nexus_repository` or `nexus_repository_group` resources. must not be defined if `rule_type` is 'blocking'.
                            'new-repository',
                            'other-repository',
                            'repository-3'
                       ]
}
```

Note: The `position` property in `nexus_repository_route` is due to a workaround.
Unfortunately, Nexus' repository routes have no writable properties that can be
used as an id. System instances are sorted and associated with catalog resources
by matching their index in the sorted list with the `position` property.

Since the instances are sorted by a randomly generated id, it may take two runs
of `puppet apply` for the resources to fall into place. Several
`nexus_repository_route` resources may be modified each time a new one is added.

### Scheduled Tasks ###

You can easily manage all of your scheduled tasks from within Puppet. For instance the following resource would setup a
task to empty the trash once a day:

```
#!puppet

nexus_scheduled_task { 'Empty Trash':
  ensure         => 'present',              # present or absent
  enabled        => true,                   # true (default) or false
  type           => 'Empty Trash',          # required, just use the name as provided in the user interface
  alert_email    => 'ops@example.com',      # optional; use `absent` (default) to disable the email notification
  reoccurrence   => 'daily',                # one of `manual` (default), `once`, `daily`, `weekly`, `monthly` or `advanced`
  start_date     => '2014-05-31',
  recurring_time => '20:00',
  task_settings  => {'EmptyTrashItemsOlderThan' => '14', 'repositoryId' => 'all_repo'},
}
```

Notes:

* `type` responds to the name or the id; if the type name is provided, the module will try to translate it to the type
  id; if that fails, the given name is passed through to Nexus. In case the given type name doesn't work, try to
  provide the type id directly
* Date and times are base on the timezone that is used on the server running Nexus. As Puppet should normally run on
  same server this shouldn't cause any trouble. However, when using the web ui on a computer with a different timezone,
  the values shown there are relative to that timezone and can appear different.
* Be very careful with one-off tasks (`reoccurrence => 'once'`); due to the way Nexus works, it will reject any updates
  of the one-off task once the scheduled date has passed. This will cause you Puppet run to fail. You have been warned.

Due to the complexity of the resource it is strongly recommended to configure the task via the user interface and use
`puppet resource` to generate the corresponding Puppet manifest.

#### Date and time related properties ###

Setting `reoccurrence` to one of the following values requires to specify additional properties:

* `manual` - no further property required
* `once` - `start_date` and `start_time`
* `hourly` - `start_date` and `start_time`
* `daily` - `start_date` and  `recurring_time`
* `weekly` - `start_date`, `recurring_time` and `recurring_day` (`recurring_day` should be a day of the _week_, e.g.
  `monday`, `tuesday`, ..., `sunday`)
* `monthly` - `start_date`, `recurring_time` and `recurring_day` (`recurring_day` should be a day of the _month_, e.g.
  1, 2, .... 29, 30, 31 or `last`)
* `advanced` - `cron_expression`

It is expected that `start_date` matches `YYYY-MM-DD` and `start_time` / `recurrence_time` match `HH:MM` (including
leading zeros). The `recurring_day` accepts multiple values as a list (e.g. `[1, 2, 'last'])`.

Furthermore, you should keep your manifest clean and not specify properties that are not required (e.g. specify
`cron_expression` for a `manual` task).

### Nexus Staging configuration ###

Note: Nexus Staging is a feature available to the professional edition only.

The Nexus Staging feature enables the usage of temporary repositories that are created on the fly. They form a staging
area where artifacts can be kept until they have been approved by QA. Have a read through chapter 11 of the Nexus book:
[Improved Releases with Nexus Staging](http://books.sonatype.com/nexus-book/reference/staging.html).

The example below shows how a staging profile can be configured from Puppet. The resource respects the
`can_delete_repositories` kill switch and won't delete staging profiles unless configured to do so.

```
#!puppet

nexus_staging_profile { 'staging-repository':
  ensure                 => present,                        # present or absent
  staging_mode           => deploy,                         # deploy, upload or both

  release_repository     => 'Public Repository',            # required; the final repository the artifacts are promoted to
  repository_target      => 'any artifact',                 # required
  target_groups          => ['Restricted Repository Group'],# required; a list of repositories groups which will contain
                                                            # the created staging repositories

  # Parameters that need to be tweaked unless Maven 2 is used
  staging_template       => 'default_hosted_release',
  repository_type        => maven2,

  searchable             => false,                          # true (default) or false
  implicitly_selectable  => false,                          # true (default) or false; the Profile Selection Strategy

  # An optional list of rule set names; they can be used to enforce certain properties of the release. Use the
  # nexus_staging_ruleset resource to manage them.
  close_rulesets         => 'Public Release',
  promote_rulesets       => 'Public Release',

  # An optional boolean flag to indicate whether to inform the uploader
  close_notify_creator   => false,
  promote_notify_creator => true,
  drop_notify_creator    => true,

  # An optional list of email addresses to be notified
  close_notify_emails    => ['john@example.com'],
  promote_notify_emails  => ['jane@example.com'],
  drop_notify_emails     => ['john@example.com', 'jane@example.com'],

  # An optional list of roles to be notified
  close_notify_roles     => ['qa'],
  promote_notify_roles   => ['developers'],
  drop_notify_roles      => [],
}
```

The following example shows how to define a Nexus staging ruleset with a couple of rules:

```
#!puppet

nexus_staging_ruleset { 'Public Release':
  ensure      => present,                                   # present or absent
  description => 'Ensure the release artifacts are unique and apply basic sanity checking.',
  rules       => [                                          # non-empty list of rules to apply (disabled rules are removed)
    'Artifact Uniqueness Validation',
    'Javadoc Validation',
    'POM Validation',
    "POM must not contain 'system' scoped dependencies",
    'Signature Validation',
    'Sources Validation',
  ],
}
```

## Nexus Security Configuration ##

Nexus' security primatives allow for flexible configuration of access control to repositories and artifacts.

Security primatives currently supported:

 * Privileges

Mixing managed an unmanaged privileges is not recommended due to assumptions made to work around limitations of Nexus' privilege REST API.

```
#!puppet

nexus_access_privilege { 'all-ro':
  description       => 'Global read-only',   #optional
  repository_target => 'any',                #required: must be an existing `repository_target`
  methods           => ['read']              #required: must contain 'read' and may also contain 'create', 'update', 'delete'

                                                   #leave repository and repository_group empty to apply the privilege to 'all repositories'
}

nexus_access_privilege { 'repo1-rw':
  description       => 'repo1 read-write',   #optional
  repository_target => 'any',                #required: must be an existing `repository_target`
  methods           => ['read',              #required: must contain 'read' and may also contain 'create', 'update', 'delete'
                        'create',
                        'update',
                        'delete',
                       ]
  repository        => 'repo1',              #required: must be an existing `repository`
}

nexus_access_privilege { 'internal-ro':
  description       => 'internal read-only', #optional
  repository_target => 'any',                #required: must be an existing `repository_target`
  methods           => ['read',              #required: must contain 'read' and may also contain 'create', 'update', 'delete'
                        'create',
                        'update',
                        'delete',
                       ]
  repository_group  => 'internal',           #required: must be an existing `repository_group`
}
```

## Nexus Generic Configuration ##

For Nexus configurations where there is no provider in this module it may be possible to use nexus_generic_settings.  This provides a low level wrapper around the Nexus REST API calls.

The REST API calls and the expected data formats can be viewed on the Nexus server by following the "Documentation" links for the plugins in the Plugin Console.  The settings_hash property will be transformed into JSON that will be POSTed or PUT to the specified api_url_fragment.

```
#!puppet

# Configure security realms to use

nexus_generic_settings { 'realms':
  api_url_fragment => '/service/local/global_settings/current',
  merge            => true, # merge the settings_hash into existing settings on the server
  settings_hash    => {
    securityRealms => [
                'XmlAuthenticatingRealm',
                'XmlAuthorizingRealm',
                'LdapAuthenticatingRealm',
                'X-NuGet-ApiKey'
            ],
  }
}

# Create an External Role Mapping

nexus_generic_settings { 'admins-role':
  api_url_fragment => '/service/local/roles',
  merge            => false,
  action           => 'create', # action is 'create' or 'update'
  settings_hash    => {
    id             => 'Package Repo Admins',
    name           => 'Package Repo Admins',
    description    => 'External Role Mapping for Package Repo Admins',
    sessionTimeout => 0,
    roles          => ['nx-admin', 'repository-any-full']
  },
  require          => Nexus_generic_settings['realms']
}

# Create a user

nexus_generic_settings { 'readonly-user':
  api_url_fragment => '/service/local/users',
  id_field         => 'userId',
  merge            => false,
  action           => 'create',
  settings_hash    => {
    userId         => 'readonly',
    firstName      => 'readonly',
    lastName       => 'readonly',
    status         => 'active',
    email          => 'noreply@example.org',
    roles          => ['repository-any-read','anonymous'],
    password       => 'secretpassword'
  }
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
* Puppet 3.6
* Puppet 3.7

It is very likely to work with any Puppet 3.x version. Support for Puppet 2.7.x has been dropped in favour of improved support for custom Puppet types and providers that is only available in Puppet 3.x.

### Nexus compatibility ###
Furthermore, the module has been tested with the following Nexus versions:

* Nexus Pro 2.11.x running on Ubuntu 12.04

### A note on passwords ###

Due to the limitation of the Nexus REST api it is not possible to retrieve the current value of a password. Hence,
Puppet can only manage the existence of the password but won't notice when passwords change. Either way, passwords will
be updated when attributes of the same resource change as well.

## Contributing ##

1. Raise an issue
2. Fork it
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new pull request targeting master
