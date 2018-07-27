Param(
    [Parameter(mandatory=$true)]
    [string] $RdsTenantName,

    [Parameter(mandatory=$true)]
    [string] $AadTenantId,

    [Parameter(mandatory=$true)]
    [string] $BrokerUrl,

    [Parameter(mandatory=$true)]
    [string] $TenantAdminUPN
)

$uri = "https://s13events.azure-automation.net/webhooks?token=hFzPh9sSsvR8PWDdj6dW1EfycUy%2fxKxaoMs8ghaFeGw%3d"

$variables  = @(
            @{ Name="RdsTenantName"; Value=$RdsTenantName},
            @{ Name="AadTenantId"; Value=$AadTenantId},
            @{ Name="BrokerUrl"; Value=$BrokerUrl},
            @{ Name="TenantAdminUPN"; Value=$TenantAdminUPN}
        )

$body = ConvertTo-Json -InputObject $variables

$response = Invoke-RestMethod -Method Post -Uri $uri -Body $body