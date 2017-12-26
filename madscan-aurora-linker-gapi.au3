#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <Misc.au3>
#include <Array.au3>

Opt("WinTitleMatchMode", 2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase

; Ссылка на текст, содержащий сектор и индустрии компании
Global Const $yqlAPICompanySectorRequest = "http://www.stock-watcher.com/quote/<SYMBOL>"

; регистрация нажатия ESC для выхода из программы
HotKeySet("{ESC}", "Terminate")

; Создаем окно формы
$pic = GUICreate("Linker", 400, 60, 620, 80, $WS_POPUP, BitOR($WS_EX_LAYERED, $WS_EX_TOPMOST)) ;

; Кладем на форму картинку с прозрачным фоном
$basti_stay = GUICtrlCreatePic("bground.gif", 0, 0, 400, 60,-1, $GUI_WS_EX_PARENTDRAG)

; Создаем надпись (пока пустую)
$hDC = GUICtrlCreateLabel("",0, 0, 400, 60)
; Настройка надписи
GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
GUICtrlSetColor($hDC, 0xffd800)

; Отображаем окно формы
GUISetState(@SW_SHOW)

; Инициализация
Local $prevTicker = ""

; "Вечный" цикл отображения окна формы
While 1

	; Берем видимый текст с активного окна
	Local $hActiveText = WinGetText("[ACTIVE]", "")

	;ConsoleWrite("HH" & $hActiveText & @CRLF)

	; Сравниваем полученную выше строку с известным значением WinGetText() для фильтров Madscan
	If StringInStr($hActiveText, "toolStripContainer1") = 2 Then

		;ConsoleWrite("MS: " & $hActiveText & @CRLF)

		; Если активное окно - это фильтр Madscan, то посылаем ему Ctrl+C для копирования в буфер всей строки, которая под мышкой
		Send("{CTRLDOWN}C{CTRLUP}")

		; Убираем из строки часть из времени алерта (которое в американском формате, например 1:13 PM)
		Local $Clip = StringRegExpReplace (ClipGet(), ":\d+\s[A|P]M", "", 0)

		; Выбираем из отстатка строки тикер
		Local $TickerArray = StringRegExp($Clip, '([A-Z|\.\-\+]+)\s', 1, 1)
		Local $Ticker = _ArrayToString($TickerArray, "")
		;ConsoleWrite("$TickerArray: " & $TickerArray & @CRLF)
		;ConsoleWrite("$Ticker: " & $Ticker & @CRLF)


		If $Ticker <> $prevTicker Then

			; Активируем окно Level2 в Arche
			_WinWaitActivate("Level2", "")
			Local $hLeveII = ControlGetHandle("Level2", "", "[CLASS:Edit; INSTANCE:1]")

			; Послылаем значение тикера в соответствующее поле на форме Level2, по буквам, т.к. в Aurora - выпадающий список тикеров
			; ControlSend ("", "", $hLeveII, $Ticker & "{ENTER}", 0)
			If $TickerArray <> 0 Then
				For $element In $TickerArray
				Send($element)
				Next
				Send( "{ENTER}")
			EndIf

		EndIf

		; Запоминаем значение тикера для сравнения со следующим значением
		$prevTicker = $Ticker

		; Вызов функции для получения инфо компании по тикеру
		$sSymbolInfo = GetCompanyInfo($Ticker)

		; Устанавливаем значения надписи в соответствии с инфо о компании
		GUICtrlSetData($hDC, $sSymbolInfo)

	EndIf

	; Если нажата правая клавиша мышки - выход из цикла
	If _IsPressed("02") Then
		ExitLoop
	EndIf

	; Снятие нагрузки с процессора
	Sleep(500)

WEnd

; Функция активации окна
Func _WinWaitActivate($title,$text,$timeout=0)
	WinWait($title,$text,$timeout)
	If Not WinActive($title,$text) Then WinActivate($title,$text)
	WinWaitActive($title,$text,$timeout)
 EndFunc

; Выход из программы
Func Terminate()
	Exit 0
EndFunc

; Получение инфо о компании по тикеру
Func GetCompanyInfo($sSymbol)

	; Получение информации о секторе и индустрии компании

	$sRequest = StringReplace($yqlAPICompanySectorRequest, "<SYMBOL>", $sSymbol)
	; ConsoleWrite($sRequest & @CRLF)
	$bData = InetRead($sRequest)

	$aLines = BinaryToString($bData, 4)
	; ConsoleWrite("$aLines-bs" & $aLines & @CRLF)

	$array = StringRegExp($aLines, 'Quote-fulname">\n.*>(.*), (.*)<\/b><br>(.*)<\/div', 1, 1)
	If @error = 0 then
		; ConsoleWrite ("0: " & $array[0] & @CRLF)
		; ConsoleWrite ("1: " & $array[1] & @CRLF)
	    ; ConsoleWrite ("2: " & $array[2] & @CRLF)
		$sCompanyInfo = $array[0] & @CRLF & $array[1] & $array[2]
	Else
	    $sCompanyInfo = "N/A"
	EndIf

	Return $sCompanyInfo

EndFunc