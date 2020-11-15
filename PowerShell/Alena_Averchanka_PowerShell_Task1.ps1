function Belong-IpAdresses-Network {
    <#
    .SYNOPSIS
        Checking IP Addresses for belongig to the same network.

    .DESCRIPTION
        Belong-IpAdresses-Network is a function that check if entering IP Addresses belong to the same network or not.

    .PARAMETER ip_address_1
        This is the first IP Address.
    
    .PARAMETER ip_address_2
        This is the second IP Address.
    
    .PARAMETER network_mask
        This is the network mask.

    .EXAMPLE
         PS C:\> Belong-IpAdresses-Network -ip_address_1 192.168.1.1 -ip_address_2 192.168.1.2 -network_mask 255.255.255.0

    .INPUTS
        Input (if any)

    .OUTPUTS
        Output (if any)
    #>
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [Net.IPAddress]$ip_address_1,

        [ValidateNotNullOrEmpty()]
        [Net.IPAddress]$ip_address_2,

        [ValidateNotNullOrEmpty()]
        [Net.IPAddress]$network_mask
    )

    #Check missing parametrs
    if (!$network_mask -or !$ip_address_2 -or !$ip_address_1) {
    	throw [System.ArgumentException]"The ip_address_1, ip_address_2, network_mask parameters are required."
    }

    #Check belonging to the same network
    if (($ip_address_1.address -band $network_mask.address) -eq ($ip_address_2.address -band $network_mask.address)) {
    	Write-Host "These IPAddresses belong to the same network."
    }
    else {
    	Write-Host "These IPAddresses don't belong to the same network."
    }
}
Get-Help "Belong-IpAdresses-Network"