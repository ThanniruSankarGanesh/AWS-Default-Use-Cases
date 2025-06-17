Install-Module -Name "AWS.Tools.Common" -AllowClobber -Force -scope CurrentUser
 Import-Module -Name "AWS.Tools.Common" -Force

Function EC2
{
param()
try
{
    Write-Output "Fetching EC2 Instances"
    $Instances=(Get-EC2Instance -Region $script:Region).Instances
    foreach($Instance in $Instances){
     #$Script:EC2Data=@()
     $InstanceID=$Instance.InstanceID
     $InsDet=Get-EC2InstanceStatus -Region $script:Region  -InstanceId $InstanceID
 
     if(($InsDet.InstanceState.Name)){
         $status = $InsDet.InstanceState.Name
         if(($InsDet.Status.Status -eq "ok") -and ($InsDet.SystemStatus.Status -eq "ok"))
         {
            $statuscheck="2/2 checks passed"
         }
         elseif(($InsDet.Status.Status -eq "ok") -or ($InsDet.SystemStatus.Status -eq "ok"))
         {
             $statuscheck = "1/2 checks passed"
         }
         else
         {
            $statuscheck = "No checks passed"
         }
     }else
     {
        $status="stopped"
        $statuscheck=" "
     }
 
     $dataRow = [pscustomobject]@{
            #"Account Name"      = $script:AccountName
            "Region" = $script:Region
            "Name"=($Instance.Tag | Where-Object -FilterScript {$_.Key -eq 'Name'}).Value
            "InstanceID" = $InstanceID
            "Availability Zone"=$InsDet.AvailabilityZone
            "Instance Type"=$Instance.InstanceType
            "Private IP Address"=$Instance.PrivateIpAddress
            "SubnetID"=$Instance.SubnetId
            "VPC ID"=$Instance.VpcId
            "Instance Status"=$status
            "Status"=$InsDet.Status.Status
            "System Status"=$InsDet.SystemStatus.Status
            "Status Check"=$statuscheck
        }
        $Script:EC2Data += $dataRow
   }
}
catch
{
     $errorLogging = "Error while logging - $($error[0].Message)"
     write-output $errorLogging
}
}
 
 
#region Variables
 
$Script:AllData=@()
$Script:EC2Data=@()
 
Write-Output "$(get-date -Format "dd_MM_yyyy_hh_mm_ss") - Script Starts"
write-output "Fetching Accounts"
$script:Account = '222634374835'
#$script:AccountName = 'AWS-NN-ConcurExpense-TST'
$script:Region = "us-east-2"
 
 
 
 
 
          EC2
     
   
 $Script:EC2Data | Export-Csv -Path "AWS_EC2_Report.csv" -NoTypeInformation -Encoding UTF8 -Force
 

 
Write-Output "Script Completed"
 
 
$fileName = "AWS_EC2_Report.csv"
$authority = "https://login.microsoftonline.com/189de737-c93a-4f5a-8b68-6f4ca9941912/oauth2/token"
$resourceUrl = "https://communication.azure.com"
$clientId = 'abddebe4-5f78-49f0-936d-c365d6b8e78d'
$pass = 'faF8Q~JZsiQGrjWr9NJQBDYJK3pJIMFl5radbaBd'
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
            Subject = 'Eops | AWS | EC2 Report'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
            <p>Please find attached NovoNordisk TST EC2 Report for your reference.</p>
            <p>
                Note that this is automatically generated email via GitHub Actions. For any queries or concerns, please reach out at AUTONOMICS-DEVOPS@HCL.COM</p>
             <p><br>Regards,</p>
             <p>EOPS AUTONOMICS</p>
             </body></html>"
         }
       
        recipients = @{
            To = @(
                
                @{
                    address = 'thanniru.sanka@hcltech.com'
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