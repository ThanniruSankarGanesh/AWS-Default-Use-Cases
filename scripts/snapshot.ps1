
Function Snapshot
{
param()
try
{
    write-output "Fetching Snapshots"
    $snapshots = Get-EC2Snapshot -Region $script:Region -OwnerId self
    foreach($snapshot in $snapshots)
    {
       $dataRow = [pscustomobject]@{
          "Account Name" =$script:AccountName
          "Snapshot Name" = ($snapshot.Tag | Where-Object -FilterScript {$_.Key -eq 'Name'}).Value
          "Snapshot ID" = $snapshot.SnapshotId
          "Description" = $snapshot.Description
          "Region" = $script:Region
          "Volume Id" = $snapshot.VolumeId
          "Size" = $snapshot.VolumeSize
          "Time Created" = $snapshot.StartTime
          "Policy ID" = ($snapshot.Tag | Where-Object -FilterScript {$_.Key -eq 'aws:dlm:lifecycle-policy-id'}).Value
          
       }
       $Script:AllData += $dataRow
    }
}
catch
{
     $errorLogging = "Error while logging - $($error[0].Message)"
     write-output $errorLogging
}
}




$Script:AllData=@()




write-output "$(get-date -Format "dd_MM_yyyy_hh_mm_ss") - Script Starts"
write-output "Fetching Accounts"

$script:Region = "us-east-2"
$script:Account = "222634374835"
$script:AccountName = 'AWS-Eops'

         
       
    
          Snapshot
     
   


if($Script:AllData){
    write-output "Creating CSV file for snapshot Data"
    $Script:AllData | Export-Csv -Path "AWS_Snapshot_Report.csv" -NoTypeInformation -Encoding UTF8 -Force

  
}
else{
    write-output "No Snapshot Data"
}


write-output "Script Completed"

$fileName = "AWS_Snapshot_Report.csv"
$authority = "https://login.microsoftonline.com/189de737-c93a-4f5a-8b68-6f4ca9941912/oauth2/token"
$resourceUrl = "https://communication.azure.com"
$clientId = 'abddebe4-5f78-49f0-936d-c365d6b8e78d'
$body = @{grant_type = "client_credentials"
          client_id = $clientId
          client_secret = $pass
          resource = 'https://communication.azure.com'
}
$response = Invoke-WebRequest -Method Post -Uri $authority -Body $body -ContentType 'application/x-www-form-urlencoded' -UseBasicParsing
$accessToken = $response.Content | ConvertFrom-Json
$accessToken.access_token
$uuid = [guid]::NewGuid().ToString()
$gmt = get-date -format U
$base64_csv = [Convert]::ToBase64String([IO.File]::ReadAllBytes($($fileName)))
 

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
            Subject = 'NovoNordisk PRD | AWS | Snapshot Report'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
            <p>Please find attached NovoNordisk PRD Snapshot Report for your reference.</p>
            <p>
                Note that this is automatically generated email via HCL ElasticOps Azure DevOps System. For any queries or concerns, please reach out at AUTONOMICS-DEVOPS@HCL.COM</p>
             <p><br>Regards,</p>
             <p>EOPS AUTONOMICS</p>
             </body></html>"
         }
        
        recipients = @{
            To = @(
                 @{
                address = 'more.pranjalthakaram@hcl.com'
                displayName = 'More Pranjal'
                }
                @{
                    address = 'thanniru.sanka@hcl.com'
                    displayName = 'sankar'
                }
                
                
            )
            Cc = @(
                
                @{
                address = 'more.pranjalthakaram@hcl.com'
                displayName = 'More Pranjal'
                }
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
        )
    } | ConvertTo-Json -Depth 100
}
(Invoke-WebRequest @params -UseBasicParsing).RawContent

