:: =============================================================================
:: CONFIGURATION
:: =============================================================================

@ECHO OFF


:: -----------------------------------------------------------------------------
:: Path to the JVM directory.
::
:: The variable JAVA_HOME should point at a 32bit JVM, as RJB is not compatible
:: with 64bit JVMs.
::
:: Example: SET JAVA_HOME=C:\Program Files (x86)\Java\jdk1.7.0_51
:: -----------------------------------------------------------------------------

SET JAVA_HOME=C:\Program Files (x86)\Java\jdk1.7.0_15


:: -----------------------------------------------------------------------------
:: Booleans to control which tests to run
:: -----------------------------------------------------------------------------

SET RUN_UNIT_TEST=1
SET RUN_INTEGRATION_TEST=0


:: =============================================================================
:: UNIT TESTS
:: =============================================================================

IF "%RUN_UNIT_TEST%" == "1" (
    SET BOSH_AGILITY_URL=
    SET BOSH_AGILITY_USER=
    SET BOSH_AGILITY_PASSWORD=

    set BOSH_AGILITY_TEMPLATE_STACK_NAME=
    set BOSH_AGILITY_TEMPLATE_CLOUD_PROVIDER=
    set BOSH_AGILITY_TEMPLATE_LOCATION=
    set BOSH_AGILITY_TEMPLATE_CREDENTIALS=
    set BOSH_AGILITY_TEMPLATE_HARDWARE_MODEL=

    bundle exec rspec spec/unit
)


:: =============================================================================
:: INTEGRATION TESTS
:: =============================================================================

IF "%RUN_INTEGRATION_TEST%" == "1" (
    SET BOSH_AGILITY_URL=https://192.168.199.103:8443
    SET BOSH_AGILITY_USER=admin
    SET BOSH_AGILITY_PASSWORD=

    set BOSH_AGILITY_TEMPLATE_STACK_NAME=vCenter 5.0 stack
    set BOSH_AGILITY_TEMPLATE_CLOUD_PROVIDER=vCenter 5.0
    set BOSH_AGILITY_TEMPLATE_LOCATION=CloudFoundry/BOSH_Cluster
    set BOSH_AGILITY_TEMPLATE_CREDENTIALS=vCenter key
    set BOSH_AGILITY_TEMPLATE_HARDWARE_MODEL=vs.small.x64

    bundle exec rspec spec/integration
)
