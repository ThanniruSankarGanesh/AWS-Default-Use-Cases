#param([String]$pass)
#Write-Output "The password is $($pass)"
Function S3Reporting{
    param()
    write-output "Fetching S3 Data"
   
       $Buckets = Get-S3Bucket  | Select-Object -ExpandProperty BucketName
    

foreach($Bucket in $Buckets){
    write-output "Fetching S3 Data for bucket $($Bucket)"
    #Current
    $daysAgo = (Get-Date ([datetime](Get-Date).AddDays(-2))) 
    $today = Get-Date
    $Statistic = 'Average'
    $standard = Get-CWMetricStatistics  -Namespace 'AWS/S3' -MetricName 'BucketSizeBytes' `
                                         -Dimension @(@{ Name = 'BucketName'; Value = "$Bucket" }; @{ Name = 'StorageType'; Value = "StandardStorage" }) `
                                         -Statistic $Statistic -Period 86400 -StartTime $daysAgo -EndTime $today

    $svalue = '{0:N2}' -f (($standard.Datapoints | Measure-Object -Property $Statistic -Maximum).Maximum / 1MB)


    $metricNumObjects = Get-CWMetricStatistics -Namespace 'AWS/S3' -MetricName 'NumberOfObjects' `
                                               -Dimension @(@{ Name = 'BucketName'; Value = "$Bucket" }; @{ Name = 'StorageType'; Value = 'AllStorageTypes' }) `
                                               -Statistic $Statistic -Period 86400 -StartTime $daysAgo -EndTime $today
    $numObjects = (($metricNumObjects.Datapoints | Measure-Object -Property $Statistic -Maximum).Maximum)

    #One Months Before
    $daysAgo = (Get-Date ([datetime](Get-Date).AddDays(-33))) 
    $today = (Get-Date ([datetime](Get-Date).AddDays(-31))) 
    $Statistic = 'Average'
    $standard = Get-CWMetricStatistics -Namespace 'AWS/S3' -MetricName 'BucketSizeBytes' `
                                         -Dimension @(@{ Name = 'BucketName'; Value = "$Bucket" }; @{ Name = 'StorageType'; Value = "StandardStorage" }) `
                                         -Statistic $Statistic -Period 86400 -StartTime $daysAgo -EndTime $today

    $s1value = '{0:N2}' -f (($standard.Datapoints | Measure-Object -Property $Statistic -Maximum).Maximum / 1MB)

    $metricNumObjects = Get-CWMetricStatistics -Namespace 'AWS/S3' -MetricName 'NumberOfObjects' `
                                               -Dimension @(@{ Name = 'BucketName'; Value = "$Bucket" }; @{ Name = 'StorageType'; Value = 'AllStorageTypes' }) `
                                               -Statistic $Statistic -Period 86400 -StartTime $daysAgo -EndTime $today
    $num1Objects = (($metricNumObjects.Datapoints | Measure-Object -Property $Statistic -Maximum).Maximum)

    #Two Months Before
    $daysAgo = (Get-Date ([datetime](Get-Date).AddDays(-63))) 
    $today = (Get-Date ([datetime](Get-Date).AddDays(-61))) 
    $Statistic = 'Average'
    $standard = Get-CWMetricStatistics -Namespace 'AWS/S3' -MetricName 'BucketSizeBytes' `
                                         -Dimension @(@{ Name = 'BucketName'; Value = "$Bucket" }; @{ Name = 'StorageType'; Value = "StandardStorage" }) `
                                         -Statistic $Statistic -Period 86400 -StartTime $daysAgo -EndTime $today

    $s2value = '{0:N2}' -f (($standard.Datapoints | Measure-Object -Property $Statistic -Maximum).Maximum / 1MB)

    $metricNumObjects = Get-CWMetricStatistics -Namespace 'AWS/S3' -MetricName 'NumberOfObjects' `
                                               -Dimension @(@{ Name = 'BucketName'; Value = "$Bucket" }; @{ Name = 'StorageType'; Value = 'AllStorageTypes' }) `
                                               -Statistic $Statistic -Period 86400 -StartTime $daysAgo -EndTime $today
    $num2Objects = (($metricNumObjects.Datapoints | Measure-Object -Property $Statistic -Maximum).Maximum)

    #Three Months Before
    $daysAgo = (Get-Date ([datetime](Get-Date).AddDays(-93))) 
    $today = (Get-Date ([datetime](Get-Date).AddDays(-91))) 
    $Statistic = 'Average'
    $standard = Get-CWMetricStatistics -Namespace 'AWS/S3' -MetricName 'BucketSizeBytes' `
                                         -Dimension @(@{ Name = 'BucketName'; Value = "$Bucket" }; @{ Name = 'StorageType'; Value = "StandardStorage" }) `
                                         -Statistic $Statistic -Period 86400 -StartTime $daysAgo -EndTime $today

    $s3value = '{0:N2}'-f (($standard.Datapoints | Measure-Object -Property $Statistic -Maximum).Maximum / 1MB)

    $metricNumObjects = Get-CWMetricStatistics -Namespace 'AWS/S3' -MetricName 'NumberOfObjects' `
                                               -Dimension @(@{ Name = 'BucketName'; Value = "$Bucket" }; @{ Name = 'StorageType'; Value = 'AllStorageTypes' }) `
                                               -Statistic $Statistic -Period 86400 -StartTime $daysAgo -EndTime $today
    $num3Objects = (($metricNumObjects.Datapoints | Measure-Object -Property $Statistic -Maximum).Maximum)



    $dataRow = [pscustomobject]@{
        "Account Name"= $script:AccountName
        "Bucket Name"=$Bucket
        "Size (In MB (N-3) Months)"=$s3value
        "Size (In MB (N-2) Months)"=$s2value
        "Size (In MB (N-1) Months)"=$s1value
        "Size (Current in MB)"=$svalue
        "Number of Objects (Before (N-3) Month)"=$num3Objects
        "Number of Objects (Before (N-2) Month)"=$num2Objects
        "Number of Objects (Before (N-1) Month)"=$num1Objects
        "Number of Objects (Current)"=$numObjects
    }
    $Script:BucketMetrics+=$dataRow

}
}

Function S3Top10{
   $BucketName=@()
$Size=@()
$Size1=@()
$AccountName1=@()
Import-Csv -Path "s3.csv" | ForEach-Object{
    $BucketName+=$_.'Bucket Name'
    $Size+=[int]$_.'Size (Current in GB)'
    $Size1+=$_.'Size (Current in GB)'
    $AccountName1+=$_.'Account Name'

}
for($i=0;$i -lt $Size.Count;++$i)
{
   for($j=$i+1;$j -lt $Size.Count;++$j)
   {
      if($Size[$i] -lt $Size[$j])
      {
         $temp = $Size[$i]
         $Size[$i]=$Size[$j]
         $Size[$j]=$temp

         $temp=$BucketName[$i]
         $BucketName[$i]=$BucketName[$j]
         $BucketName[$j]=$temp

         $temp = $Size1[$i]
         $Size1[$i]=$Size1[$j]
         $Size1[$j]=$temp

         $temp = $AccountName1[$i]
         $AccountName1[$i]=$AccountName1[$j]
         $AccountName1[$j]=$temp

      }
   }
}
$S3Top=@()
for($i=0;$i -lt 5;++$i)
{
   $data="
       <tr>
          
          <td>$($BucketName[$i])</td>
          <td>$($Size1[$i])</td>
       </tr>"
   $S3Top+=$data
}
$Script:htmlreport=@"
    <html>
    <head>
        <style>{font-family: Arial; font-size: 10pt;}
            TABLE{border: 1px solid black; border-collapse: collapse; font-size:13pt;width: 100%;}
            TH{border: 1px solid black; font-size: 10pt;background-color: Cadetblue; padding: 5px; color: white;}
            TD{border: 1px solid black; font-size: 10pt;padding: 5px; }
            body{background-color: Azure;}
            h2{background-color: Cadetblue; color: white;text-align: center;}
            p{background-color: Azure;}
            h3{background-color: Cadetblue; color: white;text-align: center;}
        </style>
    </head>
    <body>
                <h2>Top 5 Bucket by Size (In GB)</h2>
                <table>
                <tr><th>Bucket Name</th><th>Size (In MB)</th>
                </tr>
                $S3Top
                </table>
               
                <h3>Developed By - Elastic Ops Autonomics</h3>
    </body>
    </html>
"@
#$Script:htmlreport | Out-File "C:\Users\eops-autonomics\Documents\EOPS Automation\S3 Reporting\Results\TopS3.html"
}


$Script:BucketMetrics=@()
$Script:htmlreport=@()




write-output "$(get-date -Format "dd_MM_yyyy_hh_mm_ss") - Script Starts"
write-output "Fetching Accounts"
$script:Accounts = @('222634374835')
$script:AccountName = 'AWS-Eops'
$script:Regions = @("us-east-1")
    
#       S3Reporting

foreach($script:Account in $Accounts){
       foreach($script:Region in $Regions)
       {
          Write-Output "Start of Region Loop $($Region)"
          S3Reporting
          Write-Output "End of Region Loop $($Region)"

       }
       Write-Output "End of Loop"
    }

     
if($Script:BucketMetrics){
    write-output "Creating CSV file for S3 Data"
    $Script:BucketMetrics | Export-Csv -Path "AWS_S3_Report.csv" -NoTypeInformation -Encoding UTF8 -Force

    #Trigger Email
}
else{
    write-output "No S3 Buckets are there"
}



write-output "Script Completed"


$fileName = "AWS_S3_Report.csv"
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
            Subject = 'AWS | S3 Report'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
            <p>Please find attached  S3 Report for your reference.</p>
            <p>
                Note that this is automatically generated email via GitHub Actions. For any queries or concerns, please reach out at AUTONOMICS-DEVOPS@HCL.COM</p>
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
                address = 'padam.sinha@hcltech.com'
                displayName = 'Padam'
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





 

 
