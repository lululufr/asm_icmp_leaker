import socket


def parse_icmp_packet(packet):
    data = packet[32:]  # data
    return data


def capture_icmp(target_ip, output_file):
    """Capture les paquets ICMP envoyés à l'adresse spécifiée et extrait les données."""
    print(f"Capture des paquets ICMP pour l'adresse {target_ip}...")

    try:
        # socket capture paquets ICMP
        sock = socket.socket(socket.AF_INET, socket.SOCK_RAW, socket.IPPROTO_ICMP)
    except PermissionError:
        print("Vous devez exécuter ce script avec des privilèges root.")
        return

    try:
        data_buffer = b""
        while True:
            packet, addr = sock.recvfrom(65535)  # Capturer un paquet
            src_ip = addr[0]

            if src_ip == target_ip:
                data = parse_icmp_packet(packet)
                data_buffer += data
                print(f"Reçu {len(data)} octets de {src_ip}")

                if b"<<endf>>" in data:
                    break

        # Sauvegarde les données dans un fichier
        with open(output_file, "wb") as f:
            f.write(data_buffer.replace(b"<<endf>>", b""))
        print(f"Données reconstituées et sauvegardées dans {output_file}")

    except KeyboardInterrupt:
        print("\nCapture interrompue.")
    finally:
        sock.close()


target_ip = "127.0.0.1"
output_file = "output.txt"
capture_icmp(target_ip, output_file)
