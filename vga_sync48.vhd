library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY VGA_SYNC IS
	PORT(	clock_66Mhz, red, green, blue		: IN	STD_LOGIC;
			red_out, green_out, blue_out, horiz_sync_out, vert_sync_out	: OUT	STD_LOGIC;
			pixel_row, pixel_column: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
END VGA_SYNC;
ARCHITECTURE a OF VGA_SYNC IS
	SIGNAL horiz_sync, vert_sync, CLOCK_33Mhz : STD_LOGIC;
	SIGNAL video_on, video_on_v, video_on_h : STD_LOGIC;
	SIGNAL h_count, v_count :STD_LOGIC_VECTOR(9 DOWNTO 0);

BEGIN

-- video_on is high only when RGB data is displayed
video_on <= video_on_H AND video_on_V;
PROCESS
BEGIN
	WAIT UNTIL(clock_66Mhz'EVENT) AND (clock_66Mhz='1');
		CLOCK_33Mhz <= NOT CLOCK_33Mhz;
END PROCESS;


PROCESS
BEGIN
	WAIT UNTIL(clock_66Mhz'EVENT) AND (clock_66Mhz='1');
-- 800 by 600 with 48Mhz USB clock version
--Generate Horizontal and Vertical Timing Signals for Video Signal
-- H_count counts pixels (#pixels across + extra time for sync signals)
-- 
--  Horiz_sync  ------------------------------------__________--------
--  H_count     0                 #pixels           sync low      end
--
	IF (h_count = 999) THEN
   		h_count <= "0000000000";
	ELSE
   		h_count <= h_count + 1;
	END IF;

--Generate Horizontal Sync Signal using H_count
	IF (h_count <= 932) AND (h_count >= 812) THEN
 	  	horiz_sync <= '0';
	ELSE
 	  	horiz_sync <= '1';
	END IF;

--V_count counts rows of pixels (#pixel rows down + extra time for V sync signal)
--  
--  Vert_sync      -----------------------------------------------_______------------
--  V_count         0                                  last row   V sync low      end
--
	IF (v_count >= 655) AND (h_count >= 874) THEN
   		v_count <= "0000000000";
	ELSIF (h_count = 874) THEN
   		v_count <= v_count + 1;
	END IF;

-- Generate Vertical Sync Signal using V_count
	IF (v_count <= 618) AND (v_count >= 617) THEN
   		vert_sync <= '0';
	ELSE
  		vert_sync <= '1';
	END IF;

-- Generate Video on Screen Signals for Pixel Data
	IF (h_count <= 799) THEN
   		video_on_h <= '1';
   		pixel_column <= h_count;
	ELSE
	   	video_on_h <= '0';
	END IF;

	IF (v_count <= 599) THEN
   		video_on_v <= '1';
   		pixel_row <= v_count;
	ELSE
   		video_on_v <= '0';
	END IF;

-- Put all video signals through DFFs to elminate any delays that cause a blurry image
		red_out <= red AND video_on;
		green_out <= green AND video_on;
		blue_out <= blue AND video_on;
		horiz_sync_out <= horiz_sync;
		vert_sync_out <= vert_sync;

END PROCESS;
END a;
--
-- Common Video Modes - pixel clock and sync counter values
--
--  Mode       Refresh  Hor. Sync  Pixel clock  Interlaced?  VESA?
--  ------------------------------------------------------------
--  640x480     60Hz      31.5khz     25.175Mhz       No         No
--  640x480     63Hz      32.8khz     28.322Mhz       No         No
--  640x480     70Hz      36.5khz     31.5Mhz         No         No
--  640x480     72Hz      37.9khz     31.5Mhz         No        Yes
--  800x600     56Hz      35.1khz     36.0Mhz         No        Yes
--  800x600     56Hz      35.4khz     36.0Mhz         No         No
--  800x600     60Hz      37.9khz     40.0Mhz         No        Yes
--  800x600     60Hz      37.9khz     40.0Mhz         No         No
--  800x600     72Hz      48.0khz     50.0Mhz         No        Yes
--  1024x768    60Hz      48.4khz     65.0Mhz         No        Yes
--  1024x768    60Hz      48.4khz     62.0Mhz         No         No
--  1024x768    70Hz      56.5khz     75.0Mhz         No        Yes
--  1024x768    70Hz      56.25khz    72.0Mhz         No         No
--  1024x768    76Hz      62.5khz     85.0Mhz         No         No
--  1280x1024   59Hz      63.6khz    110.0Mhz         No         No
--  1280x1024   61Hz      64.24khz   110.0Mhz         No         No
--  1280x1024   74Hz      78.85khz   135.0Mhz         No         No
--
-- Pixel clock within 5% works on most monitors.
-- Faster clocks produce higher refresh rates at the same resolution
-- Some older monitors may not support higher refresh rates
-- Refresh rates below 60Hz will have some flicker
-- Bad values such as very high refresh rates may damage some monitors
-- that do not support faster refreseh rates
--
-- 640x480@60Hz Non-Interlaced mode
-- Horizontal Sync = 31.5kHz
-- Timing: H=(0.95us, 3.81us, 1.59us), V=(0.35ms, 0.064ms, 1.02ms)
--
--	        clock   horizontal timing     vertical timing      flags
--               Mhz   pixels  low     end   pixels   low     end
--640x480      25.175  640  664<->760  800    480  491<->493  525
----  sync pulses Horiz--------___------  Vert--------___-------
--
-- Alternate 640x480@60Hz Non-Interlaced mode
-- Horizontal Sync = 31.5kHz
-- Timing: H=(1.27us, 3.81us, 1.27us) V=(0.32ms, 0.06ms, 1.05ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--640x480      25.175  640  672  768  800    480  490  492  525
--
--
-- 640x480@63Hz Non-Interlaced mode (non-standard)
-- Horizontal Sync = 32.8kHz
-- Timing: H=(1.41us, 1.41us, 5.08us) V=(0.24ms, 0.092ms, 0.92ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--640x480      28.322  640  680  720  864    480  488  491  521
--
--
-- 640x480@70Hz Non-Interlaced mode (non-standard)
-- Horizontal Sync = 36.5kHz
-- Timing: H=(1.27us, 1.27us, 4.57us) V=(0.22ms, 0.082ms, 0.82ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--640x480      31.5    640  680  720  864    480  488  491  521
--
--
-- VESA 640x480@72Hz Non-Interlaced mode
-- Horizontal Sync = 37.9kHz
-- Timing: H=(0.76us, 1.27us, 4.06us) V=(0.24ms, 0.079ms, 0.74ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--640x480      31.5    640  664  704  832    480  489  492  520
--
--
-- VESA 800x600@56Hz Non-Interlaced mode
-- Horizontal Sync = 35.1kHz
-- Timing: H=(0.67us, 2.00us, 3.56us) V=(0.03ms, 0.063ms, 0.70ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      36      800  824  896 1024    600  601  603  625
--
--
-- Alternate 800x600@56Hz Non-Interlaced mode
-- Horizontal Sync = 35.4kHz
-- Timing: H=(0.89us, 4.00us, 1.11us) V=(0.11ms, 0.057ms, 0.79ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      36      800  832  976 1016    600  604  606  634
--
--
-- VESA 800x600@60Hz Non-Interlaced mode
-- Horizontal Sync = 37.9kHz
-- Timing: H=(1.00us, 3.20us, 2.20us) V=(0.03ms, 0.106ms, 0.61ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      40      800  840  968 1056    600  601  605  628 +hsync +vsync
--
--
-- Alternate 800x600@60Hz Non-Interlaced mode
-- Horizontal Sync = 37.9kHz
-- Timing: H=(1.20us, 3.80us, 1.40us) V=(0.13ms, 0.053ms, 0.69ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      40      800 848 1000 1056     600  605  607  633
--
--
-- VESA 800x600@72Hz Non-Interlaced mode
-- Horizontal Sync = 48kHz
-- Timing: H=(1.12us, 2.40us, 1.28us) V=(0.77ms, 0.13ms, 0.48ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--800x600      50      800  856  976 1040    600  637  643  666  +hsync +vsync
--
--
-- VESA 1024x768@60Hz Non-Interlaced mode
-- Horizontal Sync = 48.4kHz
-- Timing: H=(0.12us, 2.22us, 2.58us) V=(0.06ms, 0.12ms, 0.60ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     65     1024 1032 1176 1344    768  771  777  806 -hsync -vsync
--
--
-- 1024x768@60Hz Non-Interlaced mode (non-standard dot-clock)
-- Horizontal Sync = 48.4kHz
-- Timing: H=(0.65us, 2.84us, 0.65us) V=(0.12ms, 0.041ms, 0.66ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     62     1024 1064 1240 1280   768  774  776  808
--
--
-- VESA 1024x768@70Hz Non-Interlaced mode
-- Horizontal Sync=56.5kHz
-- Timing: H=(0.32us, 1.81us, 1.92us) V=(0.05ms, 0.14ms, 0.51ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     75     1024 1048 1184 1328    768  771  777  806 -hsync -vsync
--
--
-- 1024x768@70Hz Non-Interlaced mode (non-standard dot-clock)
-- Horizontal Sync=56.25kHz
-- Timing: H=(0.44us, 1.89us, 1.22us) V=(0.036ms, 0.11ms, 0.53ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     72     1024 1056 1192 1280    768  770  776 806   -hsync -vsync
--
--
-- 1024x768@76Hz Non-Interlaced mode
-- Horizontal Sync=62.5kHz
-- Timing: H=(0.09us, 1.41us, 2.45us) V=(0.09ms, 0.048ms, 0.62ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1024x768     85     1024 1032 1152 1360    768  784  787  823
--
--
-- 1280x1024@59Hz Non-Interlaced mode (non-standard)
-- Horizontal Sync=63.6kHz
-- Timing: H=(0.36us, 1.45us, 2.25us) V=(0.08ms, 0.11ms, 0.65ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1280x1024   110     1280 1320 1480 1728   1024 1029 1036 1077
--
--
-- 1280x1024@61Hz, Non-Interlaced mode
-- Horizontal Sync=64.25kHz
-- Timing: H=(0.44us, 1.67us, 1.82us) V=(0.02ms, 0.05ms, 0.41ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1280x1024   110     1280 1328 1512 1712   1024 1025 1028 1054
--
--
-- 1280x1024@74Hz, Non-Interlaced mode
-- Horizontal Sync=78.85kHz
-- Timing: H=(0.24us, 1.07us, 1.90us) V=(0.04ms, 0.04ms, 0.43ms)
--
-- name        clock   horizontal timing     vertical timing      flags
--1280x1024   135     1280 1312 1456 1712   1024 1027 1030 1064
