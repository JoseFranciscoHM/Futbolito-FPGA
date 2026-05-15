from PIL import Image
import sys
import os

def convert_to_anim_ball_vhdl(img_path, output_path, cols=8, rows=8, out_size=32):
    """
    Convierte un sprite sheet animado de un balón a un archivo VHDL ROM.
    Asume una cuadrícula uniforme (cols x rows).
    Escala cada frame al tamaño out_size x out_size.
    Formato: 4 bits por píxel [A, R, G, B].
    """
    try:
        if not os.path.exists(img_path):
            print(f"Error: No se encuentra la imagen {img_path}")
            return

        img = Image.open(img_path).convert('RGBA')
        
        frame_width_in = img.width // cols
        frame_height_in = img.height // rows
        num_frames = cols * rows
        
        pixels_per_frame = out_size * out_size
        total_pixels = num_frames * pixels_per_frame
        
        with open(output_path, 'w') as f:
            f.write("library ieee;\n")
            f.write("use ieee.std_logic_1164.all;\n")
            f.write("use ieee.numeric_std.all;\n\n")
            f.write("entity anim_ball_rom is\n")
            f.write("    port (\n")
            f.write("        address : in std_logic_vector(15 downto 0); -- 6 bits frame + 10 bits pixel\n")
            f.write("        clock   : in std_logic;\n")
            f.write("        q       : out std_logic_vector(3 downto 0)\n")
            f.write("    );\n")
            f.write("end anim_ball_rom;\n\n")
            f.write("architecture arch of anim_ball_rom is\n")
            f.write(f"    type rom_type is array (0 to {total_pixels - 1}) of std_logic_vector(3 downto 0);\n")
            f.write("    constant ROM : rom_type := (\n")
            
            first = True
            frame_idx = 0
            
            for row in range(rows):
                for col in range(cols):
                    # Extraer el frame original de la cuadrícula
                    left = col * frame_width_in
                    upper = row * frame_height_in
                    right = left + frame_width_in
                    lower = upper + frame_height_in
                    
                    frame_img = img.crop((left, upper, right, lower))
                    
                    # Redimensionar el frame al tamaño deseado (ej. 32x32)
                    frame_img = frame_img.resize((out_size, out_size), Image.Resampling.LANCZOS)
                    
                    f.write(f"        -- Frame {frame_idx}\n")
                    
                    for y in range(out_size):
                        line = "        "
                        for x in range(out_size):
                            r, g, b, a = frame_img.getpixel((x, y))
                            br = 1 if r > 127 else 0
                            bg = 1 if g > 127 else 0
                            bb = 1 if b > 127 else 0
                            active = 1 if a > 128 else 0
                            
                            val = f"\"{active}{br}{bg}{bb}\""
                            
                            if not first:
                                line += ", " + val
                            else:
                                line += val
                                first = False
                                
                        f.write(line + "\n")
                    
                    frame_idx += 1
                    
            f.write("    );\n")
            f.write("begin\n")
            f.write("    process(clock)\n")
            f.write("    begin\n")
            f.write("        if rising_edge(clock) then\n")
            f.write(f"            if to_integer(unsigned(address)) < {total_pixels} then\n")
            f.write("                q <= ROM(to_integer(unsigned(address)));\n")
            f.write("            else\n")
            f.write("                q <= \"0000\";\n")
            f.write("            end if;\n")
            f.write("        end if;\n")
            f.write("    end process;\n")
            f.write("end arch;\n")
        
        print(f"Éxito: Archivo {output_path} creado correctamente.")

    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    input_img = "SPRITES Y HEARRAMIENTAS FUTBOLITO/ball.all_.png"
    output_vhd = "anim_ball_rom.vhd"
    convert_to_anim_ball_vhdl(input_img, output_vhd)
