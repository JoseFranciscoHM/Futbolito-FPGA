from PIL import Image
import sys
import os

def convert_to_mif(img_path, output_path, width=16, height=16):
    """
    Convierte una imagen a un archivo .mif para Quartus.
    Formato: 4 bits por píxel [A, R, G, B]
    A = Bit de presencia (1 = Dibujar, 0 = Transparente)
    """
    try:
        if not os.path.exists(img_path):
            print(f"Error: No se encuentra la imagen {img_path}")
            return

        # Abrir y convertir a RGBA para manejar transparencia
        img = Image.open(img_path).convert('RGBA')
        
        # Redimensionar al tamaño del sprite
        img = img.resize((width, height), Image.Resampling.LANCZOS)
        
        with open(output_path, 'w') as f:
            f.write(f"-- Generado por Antigravity para el proyecto Futbolito\n")
            f.write(f"WIDTH=4;\n")
            f.write(f"DEPTH={width*height};\n")
            f.write(f"ADDRESS_RADIX=DEC;\n")
            f.write(f"DATA_RADIX=BIN;\n\n")
            f.write("CONTENT BEGIN\n")
            
            for y in range(height):
                for x in range(width):
                    r, g, b, a = img.getpixel((x, y))
                    
                    # Umbral para convertir a 1 bit por canal
                    br = 1 if r > 127 else 0
                    bg = 1 if g > 127 else 0
                    bb = 1 if b > 127 else 0
                    
                    # El cuarto bit indica si el píxel es visible (no es transparente)
                    active = 1 if a > 128 else 0
                    
                    # Formato [Active][Red][Green][Blue]
                    val = f"{active}{br}{bg}{bb}"
                    addr = y * width + x
                    f.write(f"    {addr} : {val};\n")
                    
            f.write("END;\n")
        
        print(f"Éxito: Archivo {output_path} creado correctamente.")
        print(f"Píxeles procesados: {width}x{height}")

    except Exception as e:
        print(f"Error durante la conversión: {str(e)}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python img_to_mif.py <imagen> [archivo_salida]")
        print("Ejemplo: python img_to_mif.py balon.png ball_sprite.mif")
    else:
        input_img = sys.argv[1]
        output_mif = sys.argv[2] if len(sys.argv) > 2 else "ball_sprite.mif"
        convert_to_mif(input_img, output_mif)
