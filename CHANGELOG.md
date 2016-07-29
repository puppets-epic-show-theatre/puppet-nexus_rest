##2016-07-26 - Release 0.8.0

Added `nexus_crowd_settings` resource to manage Crowd settings ([pull request #57](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-requests/57/buildeng-11428-nexus-crowd-provider/diff)).

##2016-06-22 - Release 0.7.0

Internal scheduled tasks are ignored by nexus_scheduled_task. They will no longer be unintentionally removed. ([pull request #54](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-requests/54)).

##2016-03-24 - Release 0.6.0

Added `nexus_ldap_settings` to manage LDAP configuration ([pull request #51](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-requests/51)).

##2016-02-29 - Release 0.5.0

Update `nexus_repository` to support hosted npm and rubygem repositories ([pull request #50](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-requests/50)).

##2015-09-16 - Release 0.4.4

This release just ships another iteration on the confinement of the rest-client so it can be installed and used in the 
same Puppet run.

* Confine rest-client as a feature within the provider ([pull request #49](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-requests/49)).

##2015-09-16 - Release 0.4.3

* Confine rest-client as a feature within the provider ([pull request #48](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-requests/48)).

##2015-06-03 - Release 0.4.2

Fixed support for `nexus_repository_groups` using non-maven format ([pull request #46](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/44)).

##2015-03-27 - Release 0.4.1

Added autorequire relationship between `nexus_repository_groups` and contained member `nexus_repository_groups` ([pull request #44](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/44))

##2015-03-18 - Release 0.4.0

Clarified requirements for running this module ([pull request #42](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/42))

One new resource:

* `nexus_access_privilege` ([pull request #39](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/39))

Bug fixes:

* Problems handling duplicate scheduled tasks ([pull request #41](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/41))
* Route validation inconsistency ([pull request #40](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/40))

##2015-02-17 - Release 0.3.0

Support for rubygems and npm repositories ([pull request #37](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/37)).

##2015-01-20 - Release 0.2.0

Two new resources

* `nexus_staging_profile` ([pull request #34](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/34)) and
* `nexus_staging_ruleset` ([pull request #32](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/32))

to support the Nexus staging feature.

Further more, the `nexus_repository_targets` resource now supports any arbitrary `provider_type` (e.g. rubygems,
[pull request #35](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/35)).

##2014-12-17 - Release 0.1.1

This fixes a bug where a successful health check was cached for too long and subsequent requests failed because Nexus 
was actually down ([pull request #31](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/31)).
