library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_BALL_TOP is
    port (
        Clock_50Mhz : in  std_logic;
        SW0         : in  std_logic; -- Reset Maestro
        -- Botones Porteros
        BTN_UP_LEFT    : in  std_logic;
        BTN_DOWN_LEFT  : in  std_logic;
        BTN_UP_RIGHT   : in  std_logic;
        BTN_DOWN_RIGHT : in  std_logic;
        -- VGA
        VGA_Red   : out std_logic_vector(7 downto 0);
        VGA_Green : out std_logic_vector(7 downto 0);
        VGA_Blue  : out std_logic_vector(7 downto 0);
        VGA_HSync   : out std_logic;
        VGA_VSync   : out std_logic;
        VGA_Clk     : out std_logic;
        VGA_Blank_N : out std_logic;
        VGA_Sync_N  : out std_logic;
        -- Audio (DFPlayer UART)
        UART_TX         : out std_logic;
        DF_BUSY         : in  std_logic; -- Pin AB21
        -- Audio Codec (Line Out)
        AUD_XCK      : buffer std_logic;
        AUD_BCLK     : inout std_logic;
        AUD_ADCLRCK  : out std_logic;
        AUD_ADCDAT   : in std_logic;
        AUD_DACLRCK  : buffer std_logic;
        AUD_DACDAT   : out std_logic;
        I2C_SCLK     : out std_logic;
        I2C_SDAT     : inout std_logic;
        -- Diagnóstico
        LEDG         : out std_logic_vector(1 downto 0)
    );
end VGA_BALL_TOP;

architecture arch of VGA_BALL_TOP is
    -- Señales internas
    signal red_wire, green_wire, blue_wire : std_logic;
    signal pixel_row, pixel_column : std_logic_vector(9 downto 0);
    signal video_on : std_logic;
    signal vert_sync_internal : std_logic;
    signal pixel_clock : std_logic;

    -- Señales de Audio
    signal music_bit   : std_logic;
    signal goal_sfx_bit: std_logic;
    signal goal_event  : std_logic;
    signal goal_busy   : std_logic;
    signal final_bit   : std_logic;
    signal codec_wave  : signed(15 downto 0);
    signal uart_tx_wire : std_logic;
    signal audio_activity_wire : std_logic;
    signal led_timer   : unsigned(24 downto 0) := (others => '0');
    signal led_pulse   : std_logic := '0';

begin

    -- Instancia del Sincronizador VGA
    vga_sync_inst : entity work.VGA_SYNC
        port map (
            clock_50Mhz    => Clock_50Mhz,
            red            => red_wire,
            green          => green_wire,
            blue           => blue_wire,
            horiz_sync_out => VGA_HSync,
            vert_sync_out  => vert_sync_internal,
            video_on       => video_on,
            pixel_clock    => pixel_clock,
            pixel_row      => pixel_row,
            pixel_column   => pixel_column
        );

    VGA_VSync <= vert_sync_internal;
    VGA_Clk   <= pixel_clock;
    VGA_Blank_N <= video_on; 
    VGA_Sync_N  <= '0';      

    -- Lógica del Juego
    ball_inst : entity work.ball
        port map (
            pixel_row       => pixel_row,
            pixel_column    => pixel_column,
            Red             => red_wire,
            Green           => green_wire,
            Blue            => blue_wire,
            Vert_sync       => vert_sync_internal,
            clk             => Clock_50Mhz,
            reset           => SW0,
            left_paddle_up    => BTN_UP_LEFT,
            left_paddle_down  => BTN_DOWN_LEFT,
            right_paddle_up   => BTN_UP_RIGHT,
            right_paddle_down => BTN_DOWN_RIGHT,
            -- Defenders
            left_defender_up    => BTN_UP_LEFT,
            left_defender_down  => BTN_DOWN_LEFT,
            right_defender_up   => BTN_UP_RIGHT,
            right_defender_down => BTN_DOWN_RIGHT,
            uart_tx    => uart_tx_wire,
            goal_event => goal_event,
            audio_activity => audio_activity_wire,
            busy_in        => DF_BUSY
        );

    -- Colores VGA
    VGA_Red   <= (others => red_wire)   when video_on = '1' else (others => '0');
    VGA_Green <= (others => green_wire) when video_on = '1' else (others => '0');
    VGA_Blue  <= (others => blue_wire)  when video_on = '1' else (others => '0');

    ------------------------------------------------------------
    -- SISTEMA DE AUDIO
    ------------------------------------------------------------
    
    -- Música de fondo (Pulo da Gaita)
    bg_music_inst : entity work.background_music
        port map (
            clk       => Clock_50Mhz,
            reset     => SW0,
            audio_out => music_bit
        );

    -- Efecto de Gol
    goal_sfx_inst : entity work.goal_sfx_player
        port map (
            clk       => Clock_50Mhz,
            reset     => SW0,
            trigger   => goal_event,
            audio_out => goal_sfx_bit,
            busy      => goal_busy
        );

    -- Mezclador: SFX tiene prioridad
    final_bit <= goal_sfx_bit when goal_busy = '1' else music_bit;

    -- Generador de onda para el Codec
    process(Clock_50Mhz)
    begin
        if rising_edge(Clock_50Mhz) then
            if final_bit = '1' then
                codec_wave <= to_signed(12000, 16);
            else
                codec_wave <= to_signed(-12000, 16);
            end if;
        end if;
    end process;

    -- Controlador de Hardware Codec
    audio_hw : entity work.Audio
        generic map ( SAMPLE_RATE => 48 )
        port map (
            clock       => Clock_50Mhz,
            reset       => SW0,
            AUD_XCK     => AUD_XCK,
            I2C_SCLK    => I2C_SCLK,
            I2C_SDAT    => I2C_SDAT,
            AUD_BCLK    => AUD_BCLK,
            AUD_DACLRCK => AUD_DACLRCK,
            AUD_ADCLRCK => AUD_ADCLRCK,
            AUD_ADCDAT  => AUD_ADCDAT,
            AUD_DACDAT  => AUD_DACDAT,
            Lin         => open, -- Lin/Rin son salidas del modulo (ADC), las dejamos abiertas
            Rin         => open,
            Lout        => codec_wave, -- Lout/Rout son entradas al modulo (DAC)
            Rout        => codec_wave
        );

    -- Lógica para hacer el LED de diagnóstico más visible (parpadeo de 0.25s)
    process(Clock_50Mhz)
    begin
        if rising_edge(Clock_50Mhz) then
            if audio_activity_wire = '1' then -- Trigger visual para CUALQUIER comando
                led_timer <= to_unsigned(12500000, 25); -- 0.25 seg
            elsif led_timer > 0 then
                led_timer <= led_timer - 1;
                led_pulse <= '1';
            else
                led_pulse <= '0';
            end if;
        end if;
    end process;

    UART_TX <= uart_tx_wire;
    -- El LEDG0 se apagará cuando haya actividad para que sea muy visible
    LEDG(0) <= not led_pulse;
    LEDG(1) <= DF_BUSY; -- ON = IDLE (Libre), OFF = BUSY (Reproduciendo)

end arch;
