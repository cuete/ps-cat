# Manages secrets in Azure Key Vault; get, update and remove
# Get a secret or list secrets from Key Vault
function Get-Secret
{
    Param (   
        [Parameter()]
        [string]$name,
        [string]$KVName
    )

    try
    {
        if(!$name)
        {
            Get-AzKeyVaultSecret -VaultName $KVName | Select-Object -ExpandProperty Name
            return
        }
        else
        {
            $secret = Get-AzKeyVaultSecret -VaultName $KVName -Name $name
            if($secret)
            {
                $secretString = $secret.SecretValue | ConvertFrom-SecureString -AsPlainText
                $secretString + " copied to clipboard"
                Set-Clipboard -Value $secretString
            }
            else
            {
                throw "Secret not found in KV"
            }
        }
    }
    catch
    {
        $_.Exception.Message
    }
}

# Upsert a secret in Key Vault
function Update-Secret
{
    Param (   
        [Parameter()]
        [string]$name,
        [string]$secretinput,
        [string]$KVName
    )

    try
    {
        $secretvalue = ConvertTo-SecureString $secretinput -AsPlainText -Force
        $secret = Set-AzKeyVaultSecret -VaultName $KVName -Name $name -SecretValue $secretvalue
        $secret.Name + " updated in KV"
    }
    catch
    {
        $_.Exception.Message
    }
}

# Remove a secret from Key Vault
function Remove-Secret
{
    Param (   
        [Parameter()]
        [string]$name,
        [string]$KVName
    )

    try
    {
        Remove-AzKeyVaultSecret -VaultName $KVName -Name $name #Soft-delete
        Remove-AzKeyVaultSecret -VaultName $KVName -Name $name -Force -InRemovedState #Purge
        $secret.Name + " removed from KV"
    }
    catch
    {
        $_.Exception.Message
    }
}

function Invoke-SecretManager
{
    Param (
        [Parameter(Position=0)]
        [string]$operation,
        [Parameter()]
        [Alias('n')]
        [string]$name,
        [Alias('s')]
        [string]$secretinput
    )

    # Validate if Azure is connected
    if ([string]::IsNullOrEmpty($(Get-AzContext).Name))
    {
        Connect-AzAccount
        Set-AzContext -Subscription "<subscription name>"
    }

    $KVName = "<your keyvault name>"
    switch ($operation)
    {
        "get" { Get-Secret -name $name -KVName $KVName }
        "update" { Update-Secret -name $name -secretinput $secretinput -KVName $KVName}
        "remove" { Remove-Secret -name $name -KVName $KVName }
        default { "Invalid operation - " + $operation }
    }
}
Export-ModuleMember -Function Invoke-SecretManager

# Manages blobs in Azure Storage; get, update and remove
# Upload a blob
function Set-Blob
{
    Param (
        [Parameter()]
        [string]$filepath,
        [string]$tag,
        [string]$folder,
        [Object]$Context,
        [string]$ContainerName
    )
    try
    {
        $tags = @{Classification = $tag}
        $filename = $filepath.Split('\')[-1]
        if($folder)
        {
            $filename = $folder + '/' + $filename
        }
        $blob = @{
            File             = $filepath
            Container        = $ContainerName
            Blob             = $filename
            Context          = $Context
            StandardBlobTier = 'Cool'
            Tag              = $tags}
        Set-AzStorageBlobContent @blob | Out-Null
    }
    catch
    {
        throw $_.Exception.Message
    }
    $filepath + " uploaded to storage"
}

# List blobs
function Get-Blobs
{
    Param (
        [Parameter()]
        [string]$tagfilter,
        [Object]$Context,
        [string]$ContainerName
    )

    try
    {
        $blobs = Get-AzStorageBlob -Container $ContainerName -Context $Context -IncludeTag | Where-Object { $_.Tags.Classification -match $tagfilter }
        $blobs | Select-Object Name, LastModified, Tags | Format-Table -AutoSize 
    }
    catch
    {
        throw $_.Exception.Message
    }
}

# Download a blob
function Save-Blob
{
    Param (
        [Parameter()]
        [string]$filename,
        [Object]$Context,
        [string]$ContainerName
    )
    try
    {
        $blob = @{
            Blob        = $filename
            Container   = $ContainerName
            Destination = $filename.Split('/')[-1]
            Context     = $Context
          }
        Get-AzStorageBlobContent @blob | Out-Null
        $filename + " downloaded from storage"
    }
    catch
    {
        throw $_.Exception.Message
    }
}

# Delete a blob
function Remove-Blob
{
    Param (
        [Parameter()]
        [string]$filename,
        [Object]$Context,
        [string]$ContainerName
    )
    try
    {
        Remove-AzStorageBlob -Blob $filename -Container $ContainerName -Context $Context
        $filename + " deleted from storage"
    }
    catch
    {
        throw $_.Exception.Message
    }
}

function Invoke-BlobManager
{
    Param (
        [Parameter(Position=0)]
        [string]$operation,
        [Parameter()]
        [Alias('f')]
        [string]$filepath,
        [Alias('t')]
        [string]$tag = 'none',
        [Alias('tf')]
        [string]$tagfilter,
        [Alias('dir')]
        [string]$folder)

    $StorageAccountName = '<storage account name>'
    $StorageAccountKey = '<storage key>'
    $ContainerName = '<container name>'
    $Context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

    switch ($operation)
    {
        "list" { Get-Blobs -tagfilter $tagfilter -ContainerName $ContainerName -Context $Context }
        "upload" { Set-Blob -filepath $filepath -tag $tag -folder $folder -ContainerName $ContainerName -Context $Context }
        "download" { Save-Blob -filename $filepath -ContainerName $ContainerName -Context $Context }
        "delete" { Remove-Blob -filename $filepath -ContainerName $ContainerName -Context $Context }
        default { "Invalid operation - " + $operation }
    }

}
Export-ModuleMember -Function Invoke-BlobManager

# Manages queues in Azure Storage; get, push and pop
# Push message to storage queue
function Push-QueueMessage
{
    Param (
        [Parameter()]
        [string]$message,
        [Object]$Context)

    $queueMessage = [Microsoft.Azure.Storage.Queue.CloudQueueMessage]::new($message)
    $queue = Get-AzStorageQueue -Context $Context
    $queue.CloudQueue.AddMessageAsync($queueMessage).Wait()
    "Pushed `"$message`" to queue"
}

# Pop message from storage queue
function Pop-QueueMessage
{
    Param (
        [Parameter()]
        [Object]$Context)

    $queue = Get-AzStorageQueue -Context $Context
    $queueMessage = $queue.CloudQueue.GetMessageAsync().Result
    Set-Clipboard -Value $queueMessage.AsString
    "`"$($queueMessage.AsString)`" copied to clipboard"
}

function Invoke-QueueManager
{
    Param (
        [Parameter(Position=0)]
        [string]$operation,
        [Parameter()]
        [Alias('m')]
        [string]$message)

    $StorageAccountName = '<storage account name>'
    $StorageAccountKey = '<storage key>`'
    $Context = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    switch ($operation)
    {
        "pop" { Pop-QueueMessage -Context $Context }
        "push" { Push-QueueMessage -message $message -Context $Context }
        default { "Invalid operation - " + $operation }
    }
}
Export-ModuleMember -Function Invoke-QueueManager
