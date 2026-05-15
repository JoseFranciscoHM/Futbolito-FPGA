from PIL import Image
import sys
import os

def convert_to_vhdl(img_path, output_path, width=16, height=16):
    """
    Convierte una imagen a un archivo ball_rom.vhd para Quartus.
    Formato: 4 bits por píxel [A, R, G, B]
    """
    try:
        if not os.path.exists(img_path):
            print(f"Error: No se encuentra la imagen {img_path}")
            return

        img = Image.open(img_path).convert('RGBA')
        img = img.resize((width, height), Image.Resampling.LANCZOS)
        
        with open(output_path, 'w') as f:
            f.write("library ieee;\n")
            f.write("use ieee.std_logic_1164.all;\n")
            f.write("use ieee.numeric_std.all;\n\n")
            f.write("entity ball_rom is\n")
            f.write("    port (\n")
            f.write("        address : in std_logic_vector(7 downto 0);\n")
            f.write("        clock   : in std_logic;\n")
            f.write("        q       : out std_logic_vector(3 downto 0)\n")
            f.write("    );\n")
            f.write("end ball_rom;\n\n")
            f.write("architecture arch of ball_rom is\n")
            f.write("    type rom_type is array (0 to 255) of std_logic_vector(3 downto 0);\n")
            f.write("    constant ROM : rom_type := (\n")
            
            for y in range(height):
                line = "        "
                for x in range(width):
                    r, g, b, a = img.getpixel((x, y))
                    br = 1 if r > 127 else 0
                    bg = 1 if g > 127 else 0
                    bb = 1 if b > 127 else 0
                    active = 1 if a > 128 else 0
                    
                    val = f"\"{active}{br}{bg}{bb}\""
                    idx = y * width + x
                    line += val
                    if idx < 255:
                        line += ", "
                f.write(line + "\n")
                
            f.write("    );\n")
            f.write("begin\n")
            f.write("    process(clock)\n")
            f.write("    begin\n")
            f.write("        if rising_edge(clock) then\n")
            f.write("            q <= ROM(to_integer(unsigned(address)));\n")
            f.write("        end if;\n")
            f.write("    end process;\n")
            f.write("end arch;\n")
        
        print(f"Éxito: Archivo {output_path} creado correctamente.")

    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    input_img = sys.argv[1] if len(sys.argv) > 1 else 'balon.png'
    output_vhd = "ball_rom.vhd"
    convert_to_vhdl(input_img, output_vhd)
