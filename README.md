# PCF Wipedown
This is a [Concourse pipeline](https://concourse-ci.org/) that deletes all apps in Cloud Foundry at 2am on a Saturday.

## Running
Copy `credentials-sample.yml` in to `credentials.yml` and edit the fields (this file is self-documenting).

Then add it to concourse using the following CLI:
```
fly -t concourse-server set-pipeline -p pcf-wipedown -c pipeline.yml -l credentials.yml
```

The script is merciless and will just delete everything that doesn't:

1. End in a `-keep` suffix
2. Exist in an org specified in `PAS_SAFE_ORGS`
3. Exist in a space specified in `PAS_SAFE_SPACES`
4. Exist in the System org

Routes will be automatically cleared regardless if they're not being used (i.e. associated with an app).
