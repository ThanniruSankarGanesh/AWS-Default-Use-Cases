param([String]$pass)
Write-Output "The password is $($pass)"
Function EC2Count{
param() 
try
{
    $Instances=(Get-EC2Instance -Region $script:Region -Credential $Credentials).Instances
    $Script:InstanceCount+=($Instances).Count
    foreach($Instance in $Instances){
        $InstanceID=$Instance.InstanceID
        $InsDet=Get-EC2InstanceStatus -Credential $Credentials -Region $script:Region -InstanceId $InstanceID
        if($InsDet.InstanceState.Name.Value -eq "running")
        {
           $Script:RunningCount = $Script:RunningCount + 1
        }
        else 
        {
           $Script:StoppedCount = $Script:StoppedCount + 1
        }
    }
    Write-Output $Script:RunningCount
    Write-Output $Script:StoppedCount 

}catch{
   $errorLW = "Error While Getting EC2: $($error[0].Message)"
   Write-Output $errorLW
  
}   
}

Function Keypair{
try{
   $Script:KPCount += (Get-EC2KeyPair -Region $script:Region -Credential $Credentials).Count
   write-output $Script:KPCount 
}catch{
   $errorLW = "Error While Getting Keypair Data: $($error[0].Message)"
   Write-Output $errorLW
}
}

Function SecurityGroup{
try{
   $Script:SGCount+=(Get-EC2SecurityGroup -Region $script:Region -Credential $Credentials).Count
   write-output $Script:SGCount
}catch{
   $errorLW = "Error While Getting Security Group Data: $($error[0].Message)"
   Write-Output $errorLW
}
}

Function NICCount{
try{
   $Script:NICount+=(Get-EC2NetworkInterface -Region $script:Region -Credential $Credentials).Count
   write-output $Script:NICount
}catch{
   $errorLW = "Error While Getting NIC Data: $($error[0].Message)"
   Write-Output $errorLW
}
}

Function Volume{
try{
   $Volumes = Get-EC2Volume -Region $script:Region -Credential $Credentials
   $Script:VCount += ($Volumes).Count
    write-output $Script:VCount
   foreach($Volume in $Volumes)
   {
       if($Volume.State -eq "available")
       { $Script:UnattachedVolume += 1 }
       else
       { $Script:AttachedVolume += 1  }
   }

}catch{
   $errorLW = "Error While Getting Volume Data: $($error[0].Message)"
   Write-Output $errorLW
}
}

Function ElasticIP{
try{
   $Script:EICount+=(Get-EC2Address -Region $script:Region -Credential $Credentials).Count
}catch{
   $errorLW = "Error While Getting ElasticIP Data: $($error[0].Message)"
   Write-Output $errorLW
}
}

Function LoadBalancer{
try{
   $Script:LBCount+=(Get-ELB2LoadBalancer -Region $script:Region -Credential $Credentials).Count
}catch{
   $errorLW = "Error While Getting LoadBalancer Data: $($error[0].Message)"
   Write-Output $errorLW
}
}

Function S3{
try{
   $Script:S3BucketCount+=(Get-S3Bucket -Region $script:Region -Credential $Credentials).Count
}catch{
   $errorLW = "Error While Getting LoadBalancer Data: $($error[0].Message)"
   Write-Output $errorLW
}
}

Function Snapshot{
try{
   $Script:Snapshot+=(Get-EC2Snapshot -Owner self -Region $script:Region -Credential $Credentials).Count
}catch{
   $errorLW = "Error While Getting LoadBalancer Data: $($error[0].Message)"
   Write-Output $errorLW
}
}

Function EC2
{
try
{
    write-output "Fetching EC2 Instances"
    $Instances=(Get-EC2Instance -Region $script:Region -Credential $Credentials).Instances
    foreach($Instance in $Instances){
     #$Script:EC2Data=@()
     $InstanceID=$Instance.InstanceID
     $InsDet=Get-EC2InstanceStatus -Region $script:Region -InstanceId $InstanceID -Credential $Credentials

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



     $dataRow = "
        <tr>
           <td>$(($Instance.Tag | Where-Object -FilterScript {$_.Key -eq 'Name'}).Value)</td>
           <td>$($InstanceID)</td>
           <td>$($InsDet.AvailabilityZone)</td>
           <td>$( $Instance.InstanceType)</td>
           <td>$($Instance.PrivateIpAddress)</td>
           <td>$( $Instance.SubnetId)</td>
           <td>$( $Instance.VpcId)</td>
           <td>$($status)</td>
           <td>$($InsDet.Status.Status)</td>
           <td>$($InsDet.SystemStatus.Status)</td>
           <td>$($statuscheck)</td>
        </tr>
        "
        $Script:EC2Data += $dataRow
   }
}
catch
{
     $errorLogging = "Error while logging - $($error[0].Message)"
     Write-Output $errorLogging
}
}

Function HTMLReport{
param()

try{

$htmlReport = $null    
$htmlReport = @"

<html>
<head>
<title>AWS Cloud Dashboard</title>
<meta charset="utf-8">
<Style>
body {
  font-family: Arial, Helvetica, sans-serif;
  background-color: #66CDAA;
}

h1{
    
  box-shadow: 5px 5px 4px 0px rgba(0, 0, 0, 0.2);
  text-align: center;
  background-color: #009879; /*#009879*/
  color: white;
}

h3{
    
  box-shadow: 5px 5px 4px 0px rgba(0, 0, 0, 0.2);
  text-align: center;
  background-color: #009879;
  color: white;
  font-size: large;
}

h2{
    
  box-shadow: 5px 5px 4px 0px rgba(0, 0, 0, 0.2);
  text-align: center;
  background-color: #009879;
  color: white;
}

.cards{
    
    display:flex;
    /* Put a card in the next row when previous cards take all width */
    flex-wrap: wrap;
    gap: 15px 15px;
}

.cards_item{
    
    background-color:#009879;
    flex-basis:12%;
    padding-left: 10px;
    padding-right: 10px;
    margin-left: 8%;
    margin-right: 1%;
    box-shadow: 5px 5px 4px 0px rgba(0, 0, 0, 0.2);
}

.cards_item > p {
    
    box-shadow: none;
    font-size: small;
}

.cards_item > h3 {
    
  box-shadow: none;
  font-size: small;
}

table, th{
  width: 100%;
  text-align: center;
  table-layout: fixed;
  border-collapse: collapse;
  border: 1px solid #009879;
  background-color: #66cdaa;  
}

th{
  background-color: #009879;
  color: white;
  
}

td{
  color: black;
  word-wrap: break-word;
  border: 1px solid #009879;
  font-size: small;
}

tr:nth-child(odd){
  background-color: cadetblue;
}
</style>
</head>
<body>
<h1>AWS Cloud Dashboard</h1>
<div>
<h2>Number Of Account: $Script:Count</h2>



<div class="cards">
     <div class="cards_item">
        <h3>EC2<h3>
        <p>$Script:InstanceCount</p>
     </div>
     <div class="cards_item">
        <h3>Running EC2<h3>
        <p>$Script:RunningCount</p>
     </div>
     <div class="cards_item">
        <h3>Stopped EC2<h3>
        <p>$Script:StoppedCount</p>
     </div>
     <div class="cards_item">
        <h3>Security Groups<h3>
        <p>$Script:SGCount</p>
    </div>
     <div class="cards_item">
        <h3>Key Pairs<h3>
        <p>$Script:KPCount</p>
     </div>
     <div class="cards_item">
        <h3>Network Interface Card<h3>
        <p>$Script:NICount</p>
     </div>
     <div class="cards_item">
        <h3>Volumes<h3>
        <p>$Script:VCount</p>
     </div>
     <div class="cards_item">
        <h3>Unattached Volumes<h3>
        <p>$Script:UnattachedVolume</p>
     </div>
     <div class="cards_item">
        <h3>Attached Volumes<h3>
        <p>$Script:AttachedVolume</p>
     </div>
     <div class="cards_item">
        <h3>Elastic IP<h3>
        <p>$Script:EICount</p>
     </div>
     <div class="cards_item">
        <h3>EC2 Snapshots<h3>
        <p>$Script:Snapshot</p>
     </div>
     <div class="cards_item">
        <h3>Load Balancers<h3>
        <p>$Script:LBCount</p>
     </div>
     <div class="cards_item">
        <h3>S3 Buckets<h3>
        <p>$Script:S3BucketCount</p>
     </div>
     
</div>



$(<### VM Inventory ###>)
<h2>EC2 Inventory</h2>
<table>
<tr>
    <th>Name</th>
    <th>InstanceID</th>
    <th>Availability Zone</th>
    <th>Instance Type</th>
    <th>Private IP Address</th>
    <th>SubnetID</th>
    <th>VPC ID</th>
    <th>Instance Status</th>
    <th>Status</th>
    <th>System Status</th>
    <th>Status Check</th>
</tr>
$Script:EC2Data
</table>

<h3>Developed By - ElasticOps Autonomics</h3> 


"@
if($htmlReport){
        
    $htmlReport | Out-File -FilePath "AWS_Cloud_Dashboard.html" -Encoding utf8 -Force 

}
}catch{
    
    write-output "Error while creating HTML file - $($error[0])"
}
}



$Script:AllData=@()
$Script:EC2Data=@()
$Script:InstanceCount = 0
$Script:RunningCount = 0
$Script:StoppedCount = 0
$Script:SGCount = 0
$Script:KPCount = 0
$Script:NICount = 0
$Script:VCount = 0
$Script:UnattachedVolume = 0
$Script:AttachedVolume = 0
$Script:EICount = 0
$Script:Snapshot = 0
$Script:S3BucketCount = 0
$Script:LBCount = 0
$Script:Count=1

write-host "Accounts"
$script:Accounts = @('222634374835')
$script:AccountName = 'AWS-Eops'
$script:Regions = @("us-east-2","eu-west-1")


foreach($script:Account in $Accounts){
       foreach($script:Region in $Regions)
       {
          Write-Output "Start of Region Loop $($Region)"
           EC2Count
     
          Keypair
         
          SecurityGroup
          
          NICCount
          
          Volume
         
          ElasticIP
   
          LoadBalancer
         
          Snapshot
        
          EC2
         
        
        S3
          Write-Output "End of Region Loop $($Region)"

       }
       Write-Output "End of Loop"
    }

          
         
    

HTMLReport
Write-Output "Script Completed"

$fileName = "AWS_Cloud_Dashboard.html"
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
            Subject = 'AWS | Dashboard'
            PlainText = 'used azure communication service'
            html = "<html><head><title> !</title></head><body><p>Greetings,</p>
            <p>Please find attached Dashboard Report for your reference.</p>
            <p>
                Note that this is automatically generated email via GitHub Actions. For any queries or concerns, please reach out at AUTONOMICS-DEVOPS@HCL.COM</p>
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
            contentType = "text/html"
            contentInBase64 = $($base64_csv)
           }
        )
    } | ConvertTo-Json -Depth 100
}
(Invoke-WebRequest @params -UseBasicParsing).RawContent










