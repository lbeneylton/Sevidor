import socket
import threading
from dotenv import load_dotenv
import os

load_dotenv(dotenv_path=".env.example")

HOST = os.getenv("HOST_SERVER")
PORT = int(os.getenv("PORTA_TCP", 5000))
UDP_PORT = int(os.getenv("PORTA_UDP", 6000))
IMAGE_PATH = os.getenv("IMAGE_PATH", "wallpaper.jpg")

clientes: list[tuple] = []
clientes_lock = threading.Lock()


def escolher_imagem(path=IMAGE_PATH) -> bytes:
    if not os.path.exists(path):
        raise FileNotFoundError(
            "Imagem não encontrada no caminho especificado.")

    with open(path, "rb") as img:
        data = img.read()
    return data


def iniciar_servidor_TCP(host=HOST, port=PORT) -> socket.socket:
    """
    Inicia o servidor TCP

    :param host: IP do servidor
    :param port: Porta do servidor
    :return: Objeto socket do servidor
    :rtype: socket.socket
    """
    # Criando servidor com IPV4 e TCP e inicia o servidor que fica aguardando conexão
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((host, port))
    server.listen()

    # Sinaliza no terminal o Servidor Online
    ip_servidor = socket.gethostbyname(socket.gethostname())
    print(f"\nServidor rodando no IP {ip_servidor}:{port}")
    return server


def enviar_imagem(conn: socket.socket, addr: tuple, data: bytes) -> None:
    # Envia tamanho da imagem
    conn.send(len(data).to_bytes(8, "big"))
    # Envia imagem
    conn.sendall(data)
    # Recebe confirmação do cliente
    status = conn.recv(1024).decode("utf-8", errors="ignore")
    print(f"[SERVIDOR] Cliente {addr} respondeu: {status}")


def servidor_tcp(data: bytes) -> None:
    # Iniciar o servidor
    server: socket.socket = iniciar_servidor_TCP()
    # A cada conexão é criada uma tread para essa conexão, para executar a tarefa
    while True:
        conn, addr = server.accept()

        # Passada a conexão, endereço do cliente e os dados da imagem para a thread
        threading.Thread(
            target=tratar_cliente,
            args=(conn, addr, data)
        ).start()


def tratar_cliente(conn: socket.socket, addr: tuple, data: bytes) -> None:
    print(f"\n[+] Cliente conectado: {addr}")
    conn.settimeout(300)

    while True:
        try:
            comando = conn.recv(1024).decode("utf-8", errors="ignore")
            if not comando:
                break
            comando = comando.strip().upper()
            print(f"\n[SERVIDOR] Comando recebido de {addr}: {comando}")

            if comando.startswith("GET_IMAGE"):
                enviar_imagem(conn, addr, data)

            elif comando.startswith("I_AM_HERE"):
                # Espera que o cliente envie: "I_AM_HERE 6000"
                parts = comando.split()
                udp_port = int(parts[1]) if len(parts) > 1 else 5005
                salvar_cliente(addr, udp_port)
                conn.send(b"Cliente registrado com sucesso!")

            elif comando == "EXIT":
                print(f"[SERVIDOR] Cliente {addr} desconectou")
                break

            else:
                conn.send(b"Comando desconhecido!")

        except (ConnectionResetError, socket.timeout):
            print(f"\n[SERVIDOR] Cliente {addr} desconectou abruptamente")
            break

        except Exception as e:
            print(f"\n[SERVIDOR] Erro ao tratar cliente {addr}: {e}")
            break


def salvar_cliente(addr: tuple, udp_port: int) -> None:
    with clientes_lock:
        cliente = (addr[0], udp_port)
        if cliente not in clientes:
            clientes.append(cliente)
            print(f"[SERVER] Cliente registrado: {cliente}")


def notificar_clientes():
    if not clientes:
        print("[SERVER] Nenhum cliente registrado para notificação.")
        return

    print(f"[SERVER] Notificando {len(clientes)} clientes...")

    with clientes_lock:
        for cliente in clientes[:]:  # Fazemos uma cópia para poder remover clientes
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                msg = "UPDATE_WALLPAPER".encode()
                sock.sendto(msg, cliente)
                sock.close()
                print(f"[SERVER] Notificação enviada para {cliente}")
            except Exception as e:
                print(f"[SERVER] Falha ao notificar {cliente}: {e}")
                clientes.remove(cliente)  # Remove cliente que falhou


if __name__ == "__main__":
    data = escolher_imagem()
    servidor_tcp(data)

    while True:
        cmd = input(
            "\nDigite 'notify' para notificar clientes ou 'exit' para sair: ").strip().lower()
        if cmd == "notify":
            notificar_clientes()
        elif cmd == "exit":
            print("Encerrando o servidor...")
            break
