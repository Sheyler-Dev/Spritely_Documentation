local NumericTextBox = {}

function NumericTextBox.new(textBox, config)
	local self = setmetatable({}, { __index = NumericTextBox })
	self.textBox = textBox
	self.decimals = config.Decimales or false
	self.negatives = config.Negativos or false
	self.allowEven = config.Pares or true
	self.allowOdd = config.Impares or true
	self.realTime = config.EditarentiempoReal or true
	self.convertOnExit = config.ConvertirNumeroAlSalir or true
	self.min = config.MinNumber or (config.Negativos and -math.huge or 0)
	self.max = config.MaxNumber or math.huge
	self.maxDecimals = config.MaxDecimals or 2
	self.onChanged = config.OnChanged or function(val) end
	self.previousValue = textBox.Text 
	self:_init()
	self.isFocused = false 
	return self
end

function NumericTextBox:_cleanText(text)
	if text == "" or text == "-" then return text end
	local pattern = self.negatives and "[^%d%.%-]" or "[^%d%.]"
	local clean = text:gsub(pattern, "")
	local parts = clean:split(".")
	if #parts > 2 then
		clean = parts[1] .. "." .. table.concat(parts, "", 2)
	end
	if self.negatives then
		local hasNeg = clean:sub(1,1) == "-"
		clean = clean:gsub("-", "")
		if hasNeg then clean = "-" .. clean end
	else
		clean = clean:gsub("-", "")
	end
	if self.decimals and clean:find("%.") then
		local base, dec = clean:match("(%-?%d*)%.(%d*)")
		base = base or ""
		dec = dec or ""
		if #dec > self.maxDecimals then
			clean = base .. "." .. dec:sub(1, self.maxDecimals)
		end
	elseif not self.decimals then
		clean = clean:gsub("%.", "")
	end
	local num = tonumber(clean)
	if num then
		if num > self.max then
			clean = tostring(self.max)
		end
		if not self.decimals then
			num = math.floor(num)
			clean = tostring(num)
		end
	end

	return clean
end

function NumericTextBox:_applyParity(value)
	if (self.allowEven and self.allowOdd) or (not self.allowEven and not self.allowOdd) then
		return value
	end
	local integerPart = math.round(value)
	local isEven = integerPart % 2 == 0
	local needsChange = (not self.allowEven and isEven) or (not self.allowOdd and not isEven)

	if needsChange then
		local newValue = integerPart + 1
		if newValue > self.max then
			newValue = integerPart - 1
		end
		if newValue < self.min then
			return math.clamp(value, self.min, self.max)
		end
		return newValue
	end

	return value
end

function NumericTextBox:_init()
	self.textBox.Focused:Connect(function()
		self.isFocused = true
		self.previousValue = self.textBox.Text
	end)
	
	self.textBox:GetPropertyChangedSignal("Text"):Connect(function()
		local cleaned = self:_cleanText(self.textBox.Text)
		if self.textBox.Text ~= cleaned then
			self.textBox.Text = cleaned
		end
		local num = tonumber(cleaned)
		if num then
			num = math.clamp(num, self.min, self.max)
			num = self:_applyParity(num)
			self.textBox.Text = tostring(num)
			self.onChanged(num)
		end
	end)

	self.textBox.FocusLost:Connect(function(enterPressed)
		self.isFocused = false
		local currentText = self.textBox.Text
		if currentText == "" or currentText == "-" then
			self.textBox.Text = self.previousValue
			return
		end

		local finalValue = tonumber(currentText)

		if finalValue then
			finalValue = math.clamp(finalValue, self.min, self.max)
			finalValue = self:_applyParity(finalValue)

			if self.convertOnExit then
				self.textBox.Text = tostring(finalValue)
			end

			self.onChanged(finalValue)
			self.previousValue = self.textBox.Text
		else
			self.textBox.Text = self.previousValue
		end

	end)
end

return NumericTextBox