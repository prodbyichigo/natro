nm_InventorySearch(item, direction:="down", prescroll:=0, prescrolldir:="", scrolltoend:=1, max:=70){ ;~ item: string of item; direction: down or up; prescroll: number of scrolls before direction switch; prescrolldir: direction to prescroll, set blank for same as direction; scrolltoend: set 0 to omit scrolling to top/bottom after prescrolls; max: number of scrolls in total
	global bitmaps
	static hRoblox:=0, l:=0

	textSearch := true
	if !ocr_intialised 
		initialiseOCR()
	TextSearch()

	firstItem := ""

	nm_OpenMenu("itemmenu")

	; detect inventory end for current hwnd
	if (hwnd := GetRobloxHWND())
	{
		if (hwnd != hRoblox)
		{
			ActivateRoblox()
			offsetY := GetYOffset(hwnd)
			GetRobloxClientPos(hwnd)
			pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY+offsetY+150 "|306|" windowHeight-offsetY-150)

			Loop 40
			{
				if (Gdip_ImageSearch(pBMScreen, bitmaps["item"], &lpos, , , 6, , 2, , 2) = 1)
				{
					Gdip_DisposeImage(pBMScreen)
					l := SubStr(lpos, InStr(lpos, ",")+1)-60 ; image 20px, item 80px => y+20-80 = y-60
					hRoblox := hwnd
					break
				}
				else
				{
					if (A_Index = 40)
					{
						Gdip_DisposeImage(pBMScreen)
						return 0
					}
					else
					{
						Sleep 50
						Gdip_DisposeImage(pBMScreen)
						pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY+offsetY+150 "|306|" windowHeight-offsetY-150)
					}
				}
			}
		}
	}
	else
		return 0 ; no roblox
	offsetY := GetYOffset(hwnd)

	; search inventory
	Loop max
	{
		ActivateRoblox()
		GetRobloxClientPos(hwnd)
		pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY+offsetY+150 "|306|" l)

		; wait for red vignette effect to disappear
		Loop 40
		{
			if (Gdip_ImageSearch(pBMScreen, bitmaps["item"], , , , 6, , 2) = 1)
				break
			else
			{
				if (A_Index = 40)
				{
					Gdip_DisposeImage(pBMScreen)
					return 0
				}
				else
				{
					Sleep 50
					Gdip_DisposeImage(pBMScreen)
					pBMScreen := Gdip_BitmapFromScreen(windowX "|" windowY+offsetY+150 "|306|" l)
				}
			}
		}

		if textSearch{
			count := 0
			imageHeight := Gdip_GetImageHeight(pBMScreen)
			lastFirstItem := firstItem
			firstItem := ""
			loop imageHeight{
				if direction = "down"{
					y := imageHeight - A_Index
					returnY := y + 190
					textBoxY := 0
				}
				else{
					y := A_Index - 1
					returnY := y -32 + 190
					textBoxY := -32
				}

				if Gdip_GetPixel(pBMScreen, 96, y) = 4294244342 ; item name background colour
				{
					count += 1
				}
				else{
					count := 0
				}

				if count = 32{ ; height of item name background
					textBox := Gdip_CloneBitmapArea(pBMScreen, 96, y + textBoxY, 210, 32)
					text := DetectInventoryText(textBox)

					text := StrReplace(text, "`r", "")
					text := StrReplace(text, "`n", "")
					text := StrReplace(text, A_Space, "")

					if (text = item){
						Gdip_DisposeImage(textBox)
						Gdip_DisposeImage(pBMScreen) 
						return [30, returnY] ; item found
					}
					else if firstItem = ""{ ;remember first item for optimisation for next loop
						firstItem := text
					}
					else if text = lastFirstItem{ ;scrolled up/down to items that where already checked
						Gdip_DisposeImage(textBox)
						break
					}
					
					Gdip_DisposeImage(textBox)
       			}
    		}
		}

		else if(Gdip_ImageSearch(pBMScreen, bitmaps[item], &pos, , , , , 10, , 5) = 1) {
			Gdip_DisposeImage(pBMScreen)
			break ; item found
		}
		Gdip_DisposeImage(pBMScreen)

		switch A_Index
		{
			case (prescroll+1): ; scroll entire inventory on (prescroll+1)th search
			if (scrolltoend = 1)
			{
				Loop 100
				{
					SendEvent "{Click " windowX+30 " " windowY+offsetY+200 " 0}"
					SendInput "{Wheel" ((direction = "down") ? "Up" : "Down") "}"
					Sleep 50
					itemName := ""
				}
			}
			default: ; scroll once
			SendEvent "{Click " windowX+30 " " windowY+offsetY+200 " 0}"
			SendInput "{Wheel" ((A_Index <= prescroll) ? (prescrolldir ? ((prescrolldir = "Down") ? "Down" : "Up") : ((direction = "down") ? "Down" : "Up")) : ((direction = "down") ? "Down" : "Up")) "}"
			Sleep 50
		}
		Sleep 500 ; wait for scroll to finish
	}
	return (pos ? [30, SubStr(pos, InStr(pos, ",")+1)+190] : 0) ; return list of coordinates for dragging
}
