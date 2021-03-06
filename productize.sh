#!/bin/bash -e

GH_PROD_BRANCH="7.2.x-devel"

if [ "$GH_USER_NAME" != "" ] && [ "$GH_USER_EMAIL" != "" ] && [ "$GH_TOKEN" != "" ] && [ "$GH_REF" != "" ]; then
    DRY_RUN="false"
else
    DRY_RUN="true"
fi

if [ "$DRY_RUN" == "false" ]; then
	git config user.name "${GH_USER_NAME}"
	git config user.email "{GH_USER_EMAIL}"
fi

if [ "$DRY_RUN" == "true" ]; then
    if ( git branch | grep 'prod_staging' &>/dev/null ); then
        echo "prod_staging branch already exists, please delete and re-run"
        exit 1
    fi
fi

# Rename Keycloak to Red Hat SSO
find . -type f -name "*README*" -exec sed -i 's@<span>Keycloak</span>@Red Hat SSO@g' {} +
# Rename WildFly to JBoss EAP
find . -type f -name "*README*" -exec sed -i 's@<span>WildFly 10</span>@JBoss EAP 7.1.0@g' {} +
find . -type f -name "*README*" -exec sed -i 's@<span>WildFly</span>@JBoss EAP@g' {} +

# Rename env
find . -type f -name "*README*" -exec sed -i 's@<span>KEYCLOAK_HOME</span>@RHSSO_HOME@g' {} +
find . -type f -name "*README*" -exec sed -i 's@<span>WILDFLY_HOME</span>@EAP_HOME@g' {} +

# Rename commands
find . -type f -name "*README*" -exec sed -i 's@KEYCLOAK_HOME/bin@RHSSO_HOME/bin@g' {} +
find . -type f -name "*README*" -exec sed -i 's@KEYCLOAK_HOME\\bin@RHSSO_HOME\\bin@g' {} +
find . -type f -name "*README*" -exec sed -i 's@WILDFLY_HOME/bin@EAP_HOME/bin@g' {} +
find . -type f -name "*README*" -exec sed -i 's@WILDFLY_HOME\\bin@EAP_HOME\\bin@g' {} +

# Remove JBoss Repo
sed -i '/<repositories>/,/<\/repositories>/ d' pom.xml

# Add RHSSO Repo
sed -i '/<\/modules>/{ 
    a \    </modules>
    a \ 
    r scripts/ssorepo.txt
    d 
}' pom.xml

# Update version to productized versions
find . -type f -name "*pom.xml*" -exec sed -i 's@SNAPSHOT</version>@redhat-2</version>@g' {} +

# Rename names in POMs
find . -type f -name "*pom.xml*" -exec sed -i 's@<name>Keycloak Quickstart@<name>Red Hat SSO Quickstart@g' {} +


git checkout -b prod_staging
git checkout action-token-authenticator/pom.xml
git checkout action-token-required-action/pom.xml 
git checkout app-springboot/pom.xml
git checkout app-springboot/README.md
git rm -r action-token-authenticator
git rm -r action-token-required-action
git rm -r app-springboot 
git status

git commit . -m "Converted to RH-SSO QuickStarts"

if [ "$DRY_RUN" == "false" ]; then
    git push --force "https://${GH_TOKEN}@${GH_REF}" prod_staging:$GH_PROD_BRANCH
else
    echo ""
    echo "Dry run, not committing"
    echo ""
fi
