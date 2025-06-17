Function OrphanDisk {
   param()
   try {
      write-output "Fetching Unattached Disks"
      #Unattached Disk
        
      $Volumes = Get-EC2Volume -Region $script:Region
      foreach ($Volume in $Volumes) {
         if ($Volume.State -eq "available") {
            #Write-Output $Volume
            $dataRow = [pscustomobject]@{
               "Account Name"      = $script:AccountName
               "Region"            = $script:Region
               "Volume Name"       = ($Volume.Tag | Where-Object -FilterScript { $_.Key -eq 'Name' }).Value
               "Volume ID"         = $Volume.VolumeID
               "Size(In GB)"       = $Volume.Size
               "State"             = $Volume.State
               "Attached To"       = $Volume.Attachments.InstanceId
               "Volume State"      = $Volume.Attachments.State
               "Availability Zone" = $Volume.AvailabilityZone
               "Created Time"      = $Volume.CreateTime
               "Volume Type"       = $Volume.VolumeType
            }
            $Script:Volumedata += $dataRow
         }
      }

        
   }    
   catch {
      $errorLogging = "Error while logging"
      write-output $errorLogging
   }
 
}

Function OrphanNIC {
   try {
      write-output "Fetching Unattached NIC details"
      Unattached NICs
        
      $NICs = Get-EC2NetworkInterface -Region $script:Region 
      foreach ($NIC in $NICs) {
         if ($NIC.Status -eq "available") {
            $dataRow = [pscustomobject]@{
               "Account Name"      = $script:AccountName
               "Region"            = $script:Region
               "NIC ID"            = $NIC.NetworkInterfaceId
               "Availability Zone" = $NIC.AvailabilityZone
               "VPC ID"            = $NIC.VpcId
               "Subnet ID"         = $NIC.SubnetId
               "State"             = $NIC.Status
            }
            $Script:NicData += $dataRow
         }
      }

        
   }    
   catch {
      $errorLogging = "Error while logging "
      write-output $errorLogging
   }
}




$Script:Volumedata = @()
$Script:NicData = @()





write-output "$(get-date -Format "dd_MM_yyyy_hh_mm_ss") - Script Starts"
write-output "Fetching Accounts"
$script:Accounts = @('222634374835')
$script:AccountName = 'AWS-Eops'
$script:Regions = @("us-east-2","eu-west-1")

foreach($script:Account in $Accounts){
       foreach($script:Region in $Regions)
       {
          Write-Output "Start of Region Loop $($Region)"
          OrphanDisk
          OrphanNIC
          Write-Output "End of Region Loop $($Region)"

       }
       Write-Output "End of Loop"
    }

      
      
write-output "Creating CSV file for Unattached NIC data "
$Script:NicData | Export-Csv -Path "AWS_Unattached_Nics.csv" -NoTypeInformation -Encoding UTF8 -Force

write-output "Creating CSV file for Unattached Disk data "
$Script:Volumedata | Export-Csv -Path "AWS_Unattached_Disks.csv" -NoTypeInformation -Encoding UTF8 -Force
write-output $Script:NicData
write-output $Script:Volumedata

write-output "Script Completed"



$fileName = "AWS_Unattached_Nics.csv"
$fileName1 = "AWS_Unattached_Disks.csv"
$authority = "https://login.microsoftonline.com/189de737-c93a-4f5a-8b68-6f4ca9941912/oauth2/token"
$resourceUrl = "https://communication.azure.com"
$clientId = 'abddebe4-5f78-49f0-936d-c365d6b8e78d'
$body = @{grant_type = "client_credentials"
          client_id = $clientId
          client_secret = 'faF8Q~JZsiQGrjWr9NJQBDYJK3pJIMFl5radbaBd'
          resource = 'https://communication.azure.com'
}
$response = Invoke-WebRequest -Method Post -Uri $authority -Body $body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing
$accessToken = $response.Content | ConvertFrom-Json
$accessToken.access_token
$uuid = [guid]::NewGuid().ToString()
$gmt = get-date -format U
$base64_csv = [Convert]::ToBase64String([IO.File]::ReadAllBytes($($fileName)))
$base64_csv1 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($($fileName1)))

$params = @{
    Method = 'POST'
    URI = 'https://eops-acs.australia.communication.azure.com/emails:send?api-version=2023-03-31'
    Headers = @{
        Authorization = 'Bearer ' + $accessToken.access_token
        'Content-Type' = 'application/json'
        'repeatability-first-sent' = $gmt
        'repeatability-request-id' = $uuid 
    }
    Body = @{
        senderAddress = 'hcl-elasticops@aa34110f-dc60-463e-b5cf-bd3b7c8ce04d.azurecomm.net'
        Content = @{
            Subject = 'Eops | AWS | Orphan Report'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
            <p>Please find attached Eops Orphan Report for your reference.</p>
            <p>
                Note that this is automatically generated email via HCL ElasticOps Azure DevOps System. For any queries or concerns, please reach out at AUTONOMICS-DEVOPS@HCL.COM</p>
             <p><br>Regards,</p>
             <p>EOPS AUTONOMICS</p>
             </body></html>"
         }
        
        recipients = @{
         To = @(
            @{
                address = 'thanniru.sanka@hcl.com'
                displayName = 'sankar'
            }
            
           
         )
         Cc = @(
           
           
            @{
                address = 'thanniru.sanka@hcl.com'
                displayName = 'sankar'
            }
        )
        }
        Attachments = @(
           @{ 
            name = $($fileName)
            contentType = "text/csv"
            contentInBase64 = $($base64_csv)
           }
           @{ 
            name = $($fileName1)
            contentType = "text/csv"
            contentInBase64 = $($base64_csv1)
           }

        )
    } | ConvertTo-Json -Depth 100
}
(Invoke-WebRequest @params -UseBasicParsing).RawContent





