## Release
***
The mapping of Harbor version and ci code branch:

| Harbor Version | CI Code Branch |
| -------------- | -------------- |  
|       master     |     master     |
|      x.y.z     |      x.y       |

The branch `master` is used to run the testing against Harbor `master` branch.  
And for the released Harbor with version `x.y.z`, use the branch `x.y`. e.g. use `2.3` to test Harbor with version `2.3.x`.


So once Harbor make a new minor releases `x.y.0`, we should do the following:
1. Make a new branch `x.y`
2. Build a new end-to-end testing engine image with tag `x.y` and push it into the repository(harbor-repo.vmware.com/harbor-ci/harbor-chart/e2e-engine).
3. Modify the shell scripts under the [directory](../resources/io/goharbor) and pin the version of e2e engine image as `x.y`.  