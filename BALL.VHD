LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ball IS
    PORT(
        pixel_row, pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        red, green, blue        : OUT STD_LOGIC;
        vert_sync : IN STD_LOGIC;
        clk       : IN STD_LOGIC;
        reset     : IN STD_LOGIC;
        left_paddle_up,   left_paddle_down   : IN STD_LOGIC;
        right_paddle_up,  right_paddle_down  : IN STD_LOGIC;
        left_defender_up, left_defender_down : IN STD_LOGIC;
        right_defender_up,right_defender_down: IN STD_LOGIC;
        uart_tx, goal_event, audio_activity  : OUT STD_LOGIC;
        busy_in : IN STD_LOGIC
    );
END ball;

ARCHITECTURE arch OF ball IS
    -- Screen / sprite sizes
    CONSTANT SW:INTEGER:=640; CONSTANT SH:INTEGER:=480;
    CONSTANT BS:INTEGER:=32;  CONSTANT PS:INTEGER:=32;
    CONSTANT SP:INTEGER:=4;
    -- X positions (left edge of sprite)
    CONSTANT LGX:INTEGER:=16;   CONSTANT LDX:INTEGER:=160;
    CONSTANT RDX:INTEGER:=448;  CONSTANT RGX:INTEGER:=592;
    -- Goal geometry
    CONSTANT GH:INTEGER:=120; CONSTANT GY0:INTEGER:=180; CONSTANT GY1:INTEGER:=300;

    -- Ball
    SIGNAL bx:INTEGER RANGE -50 TO 700:=304;
    SIGNAL by:INTEGER RANGE -50 TO 600:=224;
    SIGNAL bvx:INTEGER RANGE -8 TO 8:=3;
    SIGNAL bvy:INTEGER RANGE -8 TO 8:=2;
    -- Paddles
    SIGNAL lgy,rgy,ldy,rdy:INTEGER RANGE 0 TO 480:=224;
    -- Score
    SIGNAL lsc_tens, lsc_units : INTEGER RANGE 0 TO 9 := 0;
    SIGNAL rsc_tens, rsc_units : INTEGER RANGE 0 TO 9 := 0;
    -- Pause
    SIGNAL pf:STD_LOGIC:='0';
    SIGNAL pc:INTEGER RANGE 0 TO 600:=0;
    -- Animation
    SIGNAL ac:UNSIGNED(11 DOWNTO 0):=(OTHERS=>'0');
    SIGNAL pfrm:UNSIGNED(3 DOWNTO 0):=(OTHERS=>'0');
    SIGNAL bfrm:UNSIGNED(5 DOWNTO 0):=(OTHERS=>'0');
    -- ROM signals
    SIGNAL pral,prar:STD_LOGIC_VECTOR(13 DOWNTO 0);
    SIGNAL prql,prqr:STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL bra:STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL brq:STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL cha:STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL chr,chc:STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL cho:STD_LOGIC;
    -- Audio
    SIGNAL preq:STD_LOGIC:='0';
    SIGNAL acmd:STD_LOGIC_VECTOR(7 DOWNTO 0):=x"03";
    SIGNAL aph,apl:STD_LOGIC_VECTOR(7 DOWNTO 0):=x"00";
    TYPE ast IS (A_INIT, A_SETDEV, A_WAITDEV, A_SETVOL, A_WAIT, A_BGM_PLAY, A_BGM_RUN, A_GSTOP, A_GDLY, A_GPLAY, A_G_RUN);
    SIGNAL as_s:ast:=A_INIT;
    SIGNAL atm:INTEGER RANGE 0 TO 150000000:=0;

    -- Color decoder helper
    FUNCTION dec(q:STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
        VARIABLE rgb:STD_LOGIC_VECTOR(2 DOWNTO 0);
    BEGIN
        rgb:=q(2)&q(1)&q(0); RETURN rgb;
    END dec;

BEGIN
    pl:ENTITY work.anim_player_rom PORT MAP(address=>pral,clock=>clk,q=>prql);
    pr:ENTITY work.anim_player_rom PORT MAP(address=>prar,clock=>clk,q=>prqr);
    bl:ENTITY work.anim_ball_rom   PORT MAP(address=>bra, clock=>clk,q=>brq);
    cr:ENTITY work.Char_ROM        PORT MAP(clock=>clk,character_address=>cha,font_row=>chr,font_col=>chc,rom_mux_output=>cho);
    df:ENTITY work.dfplayer_ctrl   PORT MAP(clk=>clk,reset_n=>not reset,play_req=>preq,cmd=>acmd,param_h=>aph,param_l=>apl,uart_tx=>uart_tx);

    -- Animation counter (vert_sync = ~60Hz)
    PROCESS(vert_sync) BEGIN
        IF rising_edge(vert_sync) THEN
            ac<=ac+1;
            -- p_frame changes every 8 frames (~8fps animation)
            IF ac(2 DOWNTO 0) = "111" THEN
                IF pfrm = 8 THEN
                    pfrm <= (OTHERS => '0');
                ELSE
                    pfrm <= pfrm + 1;
                END IF;
            END IF;
            -- ball frame changes every 4 frames (faster)
            IF ac(1 DOWNTO 0) = "11" THEN
                bfrm <= bfrm + 1;
            END IF;
        END IF;
    END PROCESS;

    -- Paddle movement
    PROCESS(vert_sync,reset) BEGIN
        IF reset='1' THEN lgy<=224;rgy<=224;ldy<=224;rdy<=224;
        ELSIF rising_edge(vert_sync) THEN
            IF pf='0' THEN
                IF left_paddle_up='0'   AND lgy>SP        THEN lgy<=lgy-SP;
                ELSIF left_paddle_down='0' AND lgy<SH-PS  THEN lgy<=lgy+SP; END IF;
                ldy<=lgy;
                IF right_paddle_up='0'  AND rgy>SP        THEN rgy<=rgy-SP;
                ELSIF right_paddle_down='0' AND rgy<SH-PS THEN rgy<=rgy+SP; END IF;
                rdy<=rgy;
            END IF;
        END IF;
    END PROCESS;

    -- Ball movement + collisions
    PROCESS(vert_sync,reset)
        VARIABLE nx,ny:INTEGER;
        VARIABLE scored:BOOLEAN;
    BEGIN
        IF reset='1' THEN
            bx<=304;by<=224;bvx<=3;bvy<=2;
            lsc_tens<=0; lsc_units<=0; rsc_tens<=0; rsc_units<=0; pf<='0';pc<=0;
        ELSIF rising_edge(vert_sync) THEN
            IF pf='1' THEN
                IF pc<600 THEN pc<=pc+1;
                ELSE pc<=0;pf<='0';bx<=304;by<=224; END IF;
            ELSE
                nx:=bx+bvx; ny:=by+bvy; scored:=false;
                -- Top/bottom walls
                IF ny<=0 OR ny>=SH-BS THEN bvy<=-bvy; END IF;
                -- Left wall: goal zone scores, else bounce
                IF nx<=0 THEN
                    IF ny+BS>=GY0 AND ny<=GY1 THEN
                        IF rsc_units = 9 THEN
                            rsc_units <= 0;
                            IF rsc_tens < 9 THEN rsc_tens <= rsc_tens + 1; END IF;
                        ELSE
                            rsc_units <= rsc_units + 1;
                        END IF;
                        pf<='1'; bvx<=3; scored:=true;
                    ELSE bvx<=ABS(bvx); END IF;
                END IF;
                -- Right wall: goal zone scores, else bounce
                IF nx>=SW-BS THEN
                    IF ny+BS>=GY0 AND ny<=GY1 THEN
                        IF lsc_units = 9 THEN
                            lsc_units <= 0;
                            IF lsc_tens < 9 THEN lsc_tens <= lsc_tens + 1; END IF;
                        ELSE
                            lsc_units <= lsc_units + 1;
                        END IF;
                        pf<='1'; bvx<=-3; scored:=true;
                    ELSE bvx<=-ABS(bvx); END IF;
                END IF;
                IF NOT scored THEN
                    -- Collisions with left players
                    IF nx<=LGX+PS AND nx>=LGX-BS AND ny+BS>=lgy AND ny<=lgy+PS THEN bvx<=ABS(bvx); END IF;
                    IF nx<=LDX+PS AND nx>=LDX-BS AND ny+BS>=ldy AND ny<=ldy+PS THEN bvx<=ABS(bvx); END IF;
                    -- Collisions with right players
                    IF nx>=RDX-BS AND nx<=RDX+PS AND ny+BS>=rdy AND ny<=rdy+PS THEN bvx<=-ABS(bvx); END IF;
                    IF nx>=RGX-BS AND nx<=RGX+PS AND ny+BS>=rgy AND ny<=rgy+PS THEN bvx<=-ABS(bvx); END IF;
                    bx<=nx; by<=ny;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Address generator (combinational)
    PROCESS(pixel_column,pixel_row,bx,by,lgy,rgy,ldy,rdy,pfrm,bfrm,lsc_tens,lsc_units,rsc_tens,rsc_units,pf)
        VARIABLE x,y,px,py:INTEGER;
    BEGIN
        x:=to_integer(unsigned(pixel_column));
        y:=to_integer(unsigned(pixel_row));
        bra<=(OTHERS=>'0'); pral<=(OTHERS=>'0'); prar<=(OTHERS=>'0');
        cha<=(OTHERS=>'0'); chr<=(OTHERS=>'0'); chc<=(OTHERS=>'0');

        -- Ball ROM
        IF x>=bx AND x<bx+BS AND y>=by AND y<by+BS THEN
            py:=y-by; px:=x-bx;
            bra<=std_logic_vector(bfrm)&std_logic_vector(to_unsigned(py*32+px,10));
        END IF;

        -- Left players ROM
        IF x>=LGX AND x<LGX+PS AND y>=lgy AND y<lgy+PS THEN
            py:=y-lgy; px:=x-LGX;
            pral<=std_logic_vector(pfrm)&std_logic_vector(to_unsigned(py*32+px,10));
        ELSIF x>=LDX AND x<LDX+PS AND y>=ldy AND y<ldy+PS THEN
            py:=y-ldy; px:=x-LDX;
            pral<=std_logic_vector(pfrm)&std_logic_vector(to_unsigned(py*32+px,10));
        END IF;

        -- Right players ROM
        IF x>=RGX AND x<RGX+PS AND y>=rgy AND y<rgy+PS THEN
            py:=y-rgy; px:=x-RGX;
            prar<=std_logic_vector(pfrm)&std_logic_vector(to_unsigned(py*32+px,10));
        ELSIF x>=RDX AND x<RDX+PS AND y>=rdy AND y<rdy+PS THEN
            py:=y-rdy; px:=x-RDX;
            prar<=std_logic_vector(pfrm)&std_logic_vector(to_unsigned(py*32+px,10));
        END IF;

        -- Char ROM: "MEXICO" left name (chars: M=13,E=5,X=24,I=9,C=3,O=15), scale x2
        IF y>=4 AND y<20 THEN
            IF    x>=20  AND x<36  THEN cha<=std_logic_vector(to_unsigned(13,6));chr<=std_logic_vector(to_unsigned((y-4)/2,3));chc<=std_logic_vector(to_unsigned((x-20)/2,3));
            ELSIF x>=36  AND x<52  THEN cha<=std_logic_vector(to_unsigned(5,6)); chr<=std_logic_vector(to_unsigned((y-4)/2,3));chc<=std_logic_vector(to_unsigned((x-36)/2,3));
            ELSIF x>=52  AND x<68  THEN cha<=std_logic_vector(to_unsigned(24,6));chr<=std_logic_vector(to_unsigned((y-4)/2,3));chc<=std_logic_vector(to_unsigned((x-52)/2,3));
            ELSIF x>=68  AND x<84  THEN cha<=std_logic_vector(to_unsigned(9,6)); chr<=std_logic_vector(to_unsigned((y-4)/2,3));chc<=std_logic_vector(to_unsigned((x-68)/2,3));
            ELSIF x>=84  AND x<100 THEN cha<=std_logic_vector(to_unsigned(3,6)); chr<=std_logic_vector(to_unsigned((y-4)/2,3));chc<=std_logic_vector(to_unsigned((x-84)/2,3));
            ELSIF x>=100 AND x<116 THEN cha<=std_logic_vector(to_unsigned(15,6));chr<=std_logic_vector(to_unsigned((y-4)/2,3));chc<=std_logic_vector(to_unsigned((x-100)/2,3));
            -- "USA" lado derecho (x=524..572, escala x2): U=21 S=19 A=1
            ELSIF x>=524 AND x<540 THEN cha<=std_logic_vector(to_unsigned(21,6));chr<=std_logic_vector(to_unsigned((y-4)/2,3));chc<=std_logic_vector(to_unsigned((x-524)/2,3));
            ELSIF x>=540 AND x<556 THEN cha<=std_logic_vector(to_unsigned(19,6));chr<=std_logic_vector(to_unsigned((y-4)/2,3));chc<=std_logic_vector(to_unsigned((x-540)/2,3));
            ELSIF x>=556 AND x<572 THEN cha<=std_logic_vector(to_unsigned(1,6)); chr<=std_logic_vector(to_unsigned((y-4)/2,3));chc<=std_logic_vector(to_unsigned((x-556)/2,3));
            END IF;
        END IF;

        -- Puntuacion izquierda (Mexico) x=52..116 escala 4x (32px ancho por digito), y=22..54
        -- Puntuacion derecha  (USA)    x=524..588 escala 4x (32px ancho por digito), y=22..54
        -- Numeros 0-9 son indices 48-57
        IF y>=22 AND y<54 THEN
            IF    x>=52  AND x<84  THEN cha<=std_logic_vector(to_unsigned(48+lsc_tens,6));    chr<=std_logic_vector(to_unsigned((y-22)/4,3));chc<=std_logic_vector(to_unsigned((x-52)/4,3));
            ELSIF x>=84  AND x<116 THEN cha<=std_logic_vector(to_unsigned(48+lsc_units,6));   chr<=std_logic_vector(to_unsigned((y-22)/4,3));chc<=std_logic_vector(to_unsigned((x-84)/4,3));
            ELSIF x>=524 AND x<556 THEN cha<=std_logic_vector(to_unsigned(48+rsc_tens,6));    chr<=std_logic_vector(to_unsigned((y-22)/4,3));chc<=std_logic_vector(to_unsigned((x-524)/4,3));
            ELSIF x>=556 AND x<588 THEN cha<=std_logic_vector(to_unsigned(48+rsc_units,6));   chr<=std_logic_vector(to_unsigned((y-22)/4,3));chc<=std_logic_vector(to_unsigned((x-556)/4,3));
            END IF;
        END IF;

        -- "GOL" text when paused (G=7,O=15,L=12, scale 4x, center ~270..342, y=210..242)
        IF pf='1' AND y>=210 AND y<242 THEN
            IF    x>=270 AND x<302 THEN cha<=std_logic_vector(to_unsigned(7,6)); chr<=std_logic_vector(to_unsigned((y-210)/4,3));chc<=std_logic_vector(to_unsigned((x-270)/4,3));
            ELSIF x>=302 AND x<334 THEN cha<=std_logic_vector(to_unsigned(15,6));chr<=std_logic_vector(to_unsigned((y-210)/4,3));chc<=std_logic_vector(to_unsigned((x-302)/4,3));
            ELSIF x>=334 AND x<366 THEN cha<=std_logic_vector(to_unsigned(12,6));chr<=std_logic_vector(to_unsigned((y-210)/4,3));chc<=std_logic_vector(to_unsigned((x-334)/4,3));
            END IF;
        END IF;
    END PROCESS;

    -- Color multiplexer
    PROCESS(pixel_column,pixel_row,bx,by,lgy,rgy,ldy,rdy,prql,prqr,brq,cho,pf)
        VARIABLE x,y:INTEGER;
        VARIABLE rgb:STD_LOGIC_VECTOR(2 DOWNTO 0);
    BEGIN
        x:=to_integer(unsigned(pixel_column));
        y:=to_integer(unsigned(pixel_row));

        -- Green field
        red<='0'; green<='1'; blue<='0';

        -- Field lines (white)
        IF (x>=318 AND x<=322) OR (y>=6 AND y<=8) OR (y>=472 AND y<=474) OR (x>=6 AND x<=8) OR (x>=632 AND x<=634) THEN
            red<='1'; green<='1'; blue<='1';
        END IF;

        -- Left goalpost (white): vertical bar x=0..6, horizontal bars at GY0 and GY1
        IF x<=6 AND y>=GY0 AND y<=GY1 THEN red<='1'; green<='1'; blue<='1'; END IF;
        IF (y=GY0 OR y=GY1) AND x<=24 THEN red<='1'; green<='1'; blue<='1'; END IF;

        -- Right goalpost
        IF x>=SW-7 AND y>=GY0 AND y<=GY1 THEN red<='1'; green<='1'; blue<='1'; END IF;
        IF (y=GY0 OR y=GY1) AND x>=SW-25 THEN red<='1'; green<='1'; blue<='1'; END IF;

        -- Fondo oscuro marcador izquierdo (Mexico)
        IF y>=4 AND y<56 AND x>=16 AND x<120 THEN red<='0'; green<='0'; blue<='0'; END IF;
        -- Fondo oscuro marcador derecho (USA)
        IF y>=4 AND y<56 AND x>=520 AND x<592 THEN red<='0'; green<='0'; blue<='0'; END IF;

        -- Nombre MEXICO (verde)
        IF y>=4 AND y<20 AND x>=20 AND x<116 THEN
            IF cho='1' THEN red<='0'; green<='1'; blue<='0'; END IF;
        END IF;
        -- Nombre USA (rojo)
        IF y>=4 AND y<20 AND x>=524 AND x<572 THEN
            IF cho='1' THEN red<='1'; green<='0'; blue<='0'; END IF;
        END IF;
        -- Puntuacion Mexico (blanco)
        IF y>=22 AND y<54 AND x>=52 AND x<116 THEN
            IF cho='1' THEN red<='1'; green<='1'; blue<='1'; END IF;
        END IF;
        -- Puntuacion USA (blanco)
        IF y>=22 AND y<54 AND x>=524 AND x<588 THEN
            IF cho='1' THEN red<='1'; green<='1'; blue<='1'; END IF;
        END IF;

        -- Ball (EGA palette: R=bit2, G=bit1, B=bit0; 0000=transparent)
        IF x>=bx AND x<bx+BS AND y>=by AND y<by+BS THEN
            IF brq/="0000" THEN
                rgb:=dec(brq);
                red<=rgb(2); green<=rgb(1); blue<=rgb(0);
            END IF;
        END IF;

        -- Left players (exact sprite colors; 1111=transparent)
        IF (x>=LGX AND x<LGX+PS AND y>=lgy AND y<lgy+PS) OR
           (x>=LDX AND x<LDX+PS AND y>=ldy AND y<ldy+PS) THEN
            IF prql/="1111" AND prql/="0000" THEN
                rgb:=dec(prql);
                red<=rgb(2); green<=rgb(1); blue<=rgb(0);
            END IF;
        END IF;

        -- Right players (same sprite, different team tint can be added later)
        IF (x>=RGX AND x<RGX+PS AND y>=rgy AND y<rgy+PS) OR
           (x>=RDX AND x<RDX+PS AND y>=rdy AND y<rdy+PS) THEN
            IF prqr/="1111" AND prqr/="0000" THEN
                rgb:=dec(prqr);
                red<=rgb(2); green<=rgb(1); blue<=rgb(0);
            END IF;
        END IF;

        -- GOL text (yellow)
        IF pf='1' AND y>=210 AND y<242 AND x>=270 AND x<366 THEN
            IF cho='1' THEN red<='1'; green<='1'; blue<='0'; END IF;
        END IF;
    END PROCESS;

    -- Audio FSM
    PROCESS(clk,reset) BEGIN
        IF reset='1' THEN 
            as_s<=A_INIT; atm<=0; preq<='0';
        ELSIF rising_edge(clk) THEN
            preq<='0';
            CASE as_s IS
                WHEN A_INIT => 
                    IF atm<100000000 THEN atm<=atm+1; ELSE atm<=0; as_s<=A_SETDEV; END IF;
                WHEN A_SETDEV => 
                    -- Seleccionar Tarjeta SD (0x09, param 0x02)
                    acmd<=x"09"; apl<=x"02"; preq<='1'; atm<=0; as_s<=A_WAITDEV;
                WHEN A_WAITDEV => 
                    IF atm<25000000 THEN atm<=atm+1; ELSE atm<=0; as_s<=A_SETVOL; END IF;
                WHEN A_SETVOL => 
                    acmd<=x"06"; apl<=x"1E"; preq<='1'; atm<=0; as_s<=A_WAIT;
                WHEN A_WAIT => 
                    IF atm<25000000 THEN atm<=atm+1; ELSE atm<=0; as_s<=A_BGM_PLAY; END IF;
                WHEN A_BGM_PLAY => 
                    -- Manda reproducir desde carpeta mp3 (Comando 0x12) track 0001.mp3
                    acmd<=x"12"; apl<=x"01"; preq<='1'; atm<=0; as_s<=A_BGM_RUN;
                WHEN A_BGM_RUN => 
                    -- Ignoramos busy_in por completo. Nos quedamos aqui hasta que haya un gol.
                    -- Si el track termina, dejara de sonar. Se reiniciara despues de un gol.
                    IF pf='1' THEN 
                        as_s<=A_GSTOP; 
                    END IF;
                WHEN A_GSTOP => 
                    acmd<=x"16"; preq<='1'; atm<=0; as_s<=A_GDLY;
                WHEN A_GDLY => 
                    IF atm<10000000 THEN atm<=atm+1; ELSE atm<=0; as_s<=A_GPLAY; END IF;
                WHEN A_GPLAY => 
                    -- Reproducir desde carpeta mp3 (Comando 0x12) track 0002.mp3
                    acmd<=x"12"; apl<=x"02"; preq<='1'; as_s<=A_G_RUN;
                WHEN A_G_RUN => 
                    -- Espera a que termine la pausa de 10s del gol
                    IF pf='0' THEN as_s<=A_BGM_PLAY; END IF;
                WHEN OTHERS => 
                    as_s<=A_INIT;
            END CASE;
        END IF;
    END PROCESS;

    goal_event<=pf; audio_activity<=preq;
END arch;