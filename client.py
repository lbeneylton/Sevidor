import socket
import ctypes
import os
from PIL import Image

# -------------------------
# CONFIGURAÇÕES
# -------------------------
HOST = '127.0.0.1'
PORT = 5000
OUTPUT = "wallpaper_original.jpg"
RESIZED = "wallpaper_resized.jpg"


# -------------------------
# FUNÇÃO: obter resolução da tela
# -------------------------
def get_screen_size():
    user32 = ctypes.windll.user32
    screen_w = user32.GetSystemMetrics(0)
    screen_h = user32.GetSystemMetrics(1)
    return screen_w, screen_h


# -------------------------
# FUNÇÃO: redimensionar imagem (modo COVER)
# -------------------------
def resize_cover(input_path, screen_w, screen_h, output_path):
    img = Image.open(input_path)
    img_ratio = img.width / img.height
    screen_ratio = screen_w / screen_h

    # Ajusta pela proporção da tela sem distorcer
    if img_ratio > screen_ratio:
        new_height = screen_h
        new_width = int(new_height * img_ratio)
    else:
        new_width = screen_w
        new_height = int(new_width / img_ratio)

    img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

    # Recorte centralizado para caber exatamente na tela
    left = (new_width - screen_w) // 2
    top = (new_height - screen_h) // 2
    right = left + screen_w
    bottom = top + screen_h

    img = img.crop((left, top, right, bottom))
    img.save(output_path)

    return output_path


# -------------------------
# FUNÇÃO: solicitar imagem do servidor
# -------------------------
def solicitar_imagem():
    # IPV4 TCP
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    client.connect((HOST, PORT))

    # Recebe o tamanho da imagem
    size = int.from_bytes(client.recv(8), "big")
    print(f"Tamanho da imagem: {size} bytes")

    data = b''
    while len(data) < size:
        packet = client.recv(4096)
        if not packet:
            break
        data += packet

    with open(OUTPUT, "wb") as f:
        f.write(data)

    print(f"Imagem salva como {OUTPUT}!")

    return client





# -------------------------
# FUNÇÃO: aplicar papel de parede
# -------------------------
def alterar_papel_de_parede(caminho_imagem):
    caminho_imagem = os.path.abspath(caminho_imagem)

    try:
        ctypes.windll.user32.SystemParametersInfoW(20, 0, caminho_imagem, 3)
        print("Papel de parede alterado!")
        return "SUCESSO"
    except Exception as e:
        print(f"Falha ao alterar papel de parede: {e}")
        return "FALHA"



def registrar():
    


# -------------------------
# MAIN
# -------------------------
def main():
    # 1. Baixar imagem
    client = solicitar_imagem()

    # 2. Redimensionar para a resolução do monitor
    w, h = get_screen_size()
    resize_cover(OUTPUT, w, h, RESIZED)

    # 3. Aplicar wallpaper
    status = alterar_papel_de_parede(RESIZED)

    # 4. Enviar status ao servidor
    client.send(status.encode("utf-8"))

    # 5. Fechar
    client.close()


if __name__ == "__main__":
    main()
