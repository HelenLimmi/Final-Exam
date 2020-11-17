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