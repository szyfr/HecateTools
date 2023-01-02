package main


//= Imports
import "core:bytes"
import "core:fmt"
import "core:image"
import "core:image/png"
import "core:os"
import "core:strings"
import "vendor:raylib"


//= Main

main :: proc() {
	raylib.SetTraceLogLevel(raylib.TraceLogLevel.NONE)
	raylib.InitWindow(1280,720,"Compressor")

	for !raylib.WindowShouldClose() {

		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.WHITE)
		raylib.EndDrawing()


		//
		if raylib.IsFileDropped() {
			count   : i32 = 0 
			dropped := raylib.GetDroppedFiles(&count)
			defer raylib.ClearDroppedFiles()

			fmt.printf("Loaded:\n")
			for i:=0;i<int(count);i+=1 {
				//TODO: Get it to look in dropped directories
				fmt.printf("---%v\n",dropped[i])
			}

			//Compress
			for i:=0;i<int(count);i+=1 {
				datalen : u32 = 0
				dataRay :     = raylib.LoadFileData(dropped[i], &datalen)
				dataOdn, res := os.read_entire_file_from_filename(strings.clone_from_cstring(dropped[i]))

				//* Raylib compression (DEFLATE algorithm)
				comp1len : i32 = 0
				comp1 := raylib.CompressData(dataRay, i32(datalen), &comp1len)
				raylib.SaveFileData("_compRay.bin", comp1, u32(comp1len))

				//* Unpack png
				img, err := png.load_from_bytes(
					dataOdn,
					{},
				)
				imgBuffer : bytes.Buffer
				bytes.buffer_write_byte(&imgBuffer, u8(img.width))
				bytes.buffer_write_byte(&imgBuffer, u8(img.height))
				for o:=0;o<len(img.pixels.buf);o+=img.channels {
					col : raylib.Color = {
						img.pixels.buf[o+0],
						img.pixels.buf[o+1],
						img.pixels.buf[o+2],
						255,
					}

					switch col {
						case { 56, 56, 56,255}: bytes.buffer_write_byte(&imgBuffer, 0)
						case {107,107,107,255}: bytes.buffer_write_byte(&imgBuffer, 1)
						case {173,173,173,255}: bytes.buffer_write_byte(&imgBuffer, 2)
						case {222,255,222,255}: bytes.buffer_write_byte(&imgBuffer, 3)
						case {181,255, 82,255}: bytes.buffer_write_byte(&imgBuffer, 4)
						case { 99,206,  8,255}: bytes.buffer_write_byte(&imgBuffer, 5)
						case { 51,142,  0,255}: bytes.buffer_write_byte(&imgBuffer, 6)
						case { 41,115,  0,255}: bytes.buffer_write_byte(&imgBuffer, 7)
						case {189,189,255,255}: bytes.buffer_write_byte(&imgBuffer, 8)
						case {107, 99,255,255}: bytes.buffer_write_byte(&imgBuffer, 9)
						case { 68, 56,101,255}: bytes.buffer_write_byte(&imgBuffer, 10)
						case {255,156,197,255}: bytes.buffer_write_byte(&imgBuffer, 11)
						case {247, 82, 49,255}: bytes.buffer_write_byte(&imgBuffer, 12)
						case {147, 98,139,255}: bytes.buffer_write_byte(&imgBuffer, 13)
						case {102, 39,114,255}: bytes.buffer_write_byte(&imgBuffer, 14)
						case {255,255, 58,255}: bytes.buffer_write_byte(&imgBuffer, 15)
						case {200,200,  0,255}: bytes.buffer_write_byte(&imgBuffer, 16)
						case {197,148, 58,255}: bytes.buffer_write_byte(&imgBuffer, 17)
						case {165,123, 25,255}: bytes.buffer_write_byte(&imgBuffer, 18)
						case {255,156, 86,255}: bytes.buffer_write_byte(&imgBuffer, 19)
						case {255,132,  8,255}: bytes.buffer_write_byte(&imgBuffer, 20)
					}
				}

				//* My compression
				buffer1 : bytes.Buffer = compress(dataOdn)
				buffer2 : bytes.Buffer = compress(imgBuffer)

				comp2 : []u8 = bytes.buffer_to_bytes(&buffer1)
				os.write_entire_file("_compSzy_raw.bin", comp2)

				comp3 : []u8 = bytes.buffer_to_bytes(&imgBuffer)
				os.write_entire_file("_compSzy_img.bin", comp3)

				comp4 : []u8 = bytes.buffer_to_bytes(&buffer2)
				os.write_entire_file("_compSzy_com.bin", comp4)

				raylib.UnloadFileData(dataRay)
			}
		}
	}
}

compress :: proc{ compress_array, compress_buffer }
compress_array :: proc(
	data : []u8,
) -> bytes.Buffer {
	buffer : bytes.Buffer
	
	length : u64 = u64(data[0]*data[1])
	bytes.buffer_write_byte(&buffer, byte(length >> 0))
	bytes.buffer_write_byte(&buffer, byte(length >> 8))
	bytes.buffer_write_byte(&buffer, byte(length >> 16))
	bytes.buffer_write_byte(&buffer, byte(length >> 24))
	bytes.buffer_write_byte(&buffer, byte(length >> 32))
	bytes.buffer_write_byte(&buffer, byte(length >> 40))
	bytes.buffer_write_byte(&buffer, byte(length >> 48))
	bytes.buffer_write_byte(&buffer, byte(length >> 56))

	count : u8 = 1
	for o:=0;o<len(data)-1;o+=1 {
		if data[o+1] == data[o] {
			count += 1
		} else {
			bytes.buffer_write_byte(&buffer, count)
			bytes.buffer_write_byte(&buffer, data[o])
			count = 1
		}
		if o==len(data)-2 {
			bytes.buffer_write_byte(&buffer, count)
			bytes.buffer_write_byte(&buffer, data[o+1])
		}
	}

	return buffer
}
compress_buffer :: proc(
	data : bytes.Buffer,
) -> bytes.Buffer {
	buffer : bytes.Buffer
	
	length : u64 = u64(data.buf[0]) * u64(data.buf[1])
	fmt.printf("%v*%v=%v\n",data.buf[0],data.buf[1],length)
	bytes.buffer_write_byte(&buffer, u8(length >>  0))
	bytes.buffer_write_byte(&buffer, u8(length >>  8))
	bytes.buffer_write_byte(&buffer, u8(length >> 16))
	bytes.buffer_write_byte(&buffer, u8(length >> 24))
	bytes.buffer_write_byte(&buffer, u8(length >> 32))
	bytes.buffer_write_byte(&buffer, u8(length >> 40))
	bytes.buffer_write_byte(&buffer, u8(length >> 48))
	bytes.buffer_write_byte(&buffer, u8(length >> 56))

	count : u8 = 1
	for o:=0;o<len(data.buf)-1;o+=1 {
		if data.buf[o+1] == data.buf[o] {
			count += 1
		} else {
			bytes.buffer_write_byte(&buffer, count)
			bytes.buffer_write_byte(&buffer, data.buf[o])
			count = 1
		}
		if o==len(data.buf)-2 {
			bytes.buffer_write_byte(&buffer, count)
			bytes.buffer_write_byte(&buffer, data.buf[o+1])
		}
	}

	return buffer
}