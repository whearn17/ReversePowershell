import socket

# Define the IP address and port to listen on
local_ip = "localhost"
local_port = 80

# Create a TCP socket to listen for incoming connections
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_socket.bind((local_ip, local_port))
server_socket.listen()
socket.setdefaulttimeout(2)

print(f"Listening for incoming connections on {local_ip}:{local_port}...")

while True:
    # Wait for an incoming connection
    client_socket, client_address = server_socket.accept()
    print(f"Received connection from {client_address[0]}:{client_address[1]}")

    while True:
        try:
            command = input("$ ")

            # Send the output back to the client
            client_socket.send(command.encode())

            # Recieve output
            output = client_socket.recv(8192).decode()
            output = "\n".join([line for line in output.splitlines() if line.strip()])

            print(output)

        except ConnectionResetError:
            break
        except ConnectionAbortedError:
            break
        except socket.timeout:
            break
        except KeyboardInterrupt:
            client_socket.close()
            exit(0)

    # Close the client connection
    client_socket.close()
