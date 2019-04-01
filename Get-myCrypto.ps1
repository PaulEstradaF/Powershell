function Get-myCrypto {
    [cmdletbinding()]
    Param(
    [Switch]$showTotal
    )
    BEGIN {
        # Checks if the module CoinbasePro-Powershell.
        $cbInstalled = (Get-Module coinbasepro-powershell)
        if ($cbInstalled -eq $null) {
            Write-Output ""
            Write-Host " The module, CoinbasePro-Powershell, is not installed. Please install it before using this command." -ForegroundColor Yellow
            Break
            }   
        # Gathers current cryptocurrency values.
        [Double]$ltc = (Get-CoinbaseProductTicker -ProductID LTC-USD).Price
        [Double]$xlm = (Get-CoinbaseProductTicker -ProductID XLM-USD).Price
        [Double]$bat = (Get-CoinbaseProductTicker -ProductID BAT-USDC).Price
        [Double]$eth = (Get-CoinbaseProductTicker -ProductID ETH-USD).Price
        }    
    PROCESS {
        # This hashtable contains the name of the cryptocurrency along with the current price.
        $totalAmount_props = @{
            LTC = $ltc
            XLM = $xlm
            BAT = $bat
            ETH = $eth
            }
        # This hashtable contains the current amount of each crypto currency that I have.
        $myAmount = @{
            LTC = [Double]96.95026785
            XLM = [Double]1344.54913960
            BAT = [Double]499.99993945
            ETH = [Double]8.0422564
            }
        # This foreach loop is saved to a variable so that the variable can be referenced after
        # the loop completes.
        $Results = foreach ($CC in $totalAmount_props.Keys){
            # Creates an ordered hashtable with the names and values that will be used as properties
            # for the custom objects being created for each currency.
            $usdAmount = $totalAmount_props["$cc"] * $myAmount["$cc"]
            $props =  [Ordered]@{
                Currency = $CC
                'Amount Owned' = $myAmount["$CC"]
                'Current Value' = $totalAmount_props["$cc"]
                'Total Value (USD)' = [math]::Round($usdAmount,2)
                }
            # Creates the objects and outputs the results for each currency. Each object gets stored
            # in the $results variable
            $obj = New-Object -TypeName psobject -Property $props
            $obj
            }
        # Displays the results.
        $Results
        }
    End {
        # If the $showTotal switch was used, the command will combine the total USD amount
        if ($showTotal) {
            $Results.'Total Value (USD)' | foreach $_ {$total = $_ + $total}
            Write-Output ""
            Write-Output " Your current cryptocurrency value is $($total)."
            }
        }
}
