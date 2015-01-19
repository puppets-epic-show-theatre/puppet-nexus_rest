##2015-01-XX - Release 0.2.0

Two new resources

* `nexus_staging_profile` ([pull request #34](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/34)) and
* `nexus_staging_ruleset` ([pull request #32](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/32))

to support the Nexus staging feature.

Further more, the `nexus_repository_targets` resource now supports any arbitrary `provider_type` (e.g. rubygems,
[pull request #35](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/35)).

##2014-12-17 - Release 0.1.1

This fixes a bug where a successful health check was cached for too long and subsequent requests failed because Nexus 
was actually down ([pull request #31](https://bitbucket.org/atlassian/puppet-module-nexus_rest/pull-request/31)).
