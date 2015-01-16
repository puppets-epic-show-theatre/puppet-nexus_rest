##2015-01-XX - Release 0.2.0

Add two new resources `nexus_staging_profile` and `nexus_staging_ruleset` to support the Nexus staging feature.

##2014-12-17 - Release 0.1.1

This fixes a bug where a successful health check was cached for too long and subsequent requests failed because Nexus 
was actually down (pull request #31).
