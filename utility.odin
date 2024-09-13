package mazecraze

import "core:fmt"

to_cstring :: proc(num: any) -> cstring {
	return fmt.ctprintf("%v", num) 
}

