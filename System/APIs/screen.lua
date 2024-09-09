function drawRect(x,y,w,h,bColor, isFilled, fColor)
    OldColor = term.getBackgroundColor()
    cColor = term.getBackgroundColor()
    for i = 1, h do
        term.setCursorPos(x,y+(i-1))    
        term.setBackgroundColor(bColor)
        term.write(string.rep(" ",w))
    end
    if not(IsFilled) then
        for i = 1, (h-2) do
            term.setCursorPos(x+1,y+1+(i-1))
            term.setBackgroundColor((fColor == nil and OldColor) or fColor)
            term.write(string.rep(" ",w-2))
        end
    end
end

function drawText(x,y,s,bColor,tColor)
    term.setCursorPos((type(x) == "number" and x) or (x.mode == "center" and math.floor((x.x - string.len(s))/2 + 1)),y)
    term.setBackgroundColor((bColor == nil and term.getBackgroundColor()) or bColor)
    term.setTextColor((tColor == nil and term.getTextColor()) or tColor)
    term.write(s)
end

function clear(bColor,tColor,x,y)
    term.setBackgroundColor((bColor == nil and colors.black) or bColor)
    term.setTextColor((tColor == nil and colors.white) or tColor)
    term.setCursorPos((x == nil and 1) or x, (y == nil and 1) or y)
    term.clear()
end

function clearLine(y,bColor)
    term.setBackgroundColor((bColor == nil and colors.black) or bColor)
    term.setCursorPos(1,y)
    term.clearLine()
end

return {
    drawRect = drawRect, 
    drawText = drawText, 
    clear = clear,
    clearLine = clearLine,
}
