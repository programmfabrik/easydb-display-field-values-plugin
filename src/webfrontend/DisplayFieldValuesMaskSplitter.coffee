class ez5.DisplayFieldValuesMaskSplitter extends CustomMaskSplitter

	@FIELD_NAMES_REGEXP = /%([a-z][a-z0-9_:]{0,61}[a-z0-9])%/g

	isSimpleSplit: ->
		return true

	renderAsField: ->
		return true

	getOptions: ->
		textHintButton = new CUI.Button
			text: $$("display-field-values.custom.splitter.text.hint-text")
			appearance: "flat"
			onClick: =>
				fieldNames = []
				for node in @father.children
					fieldName = node.getData().field_name
					if not fieldName
						continue
					fieldNames.push(fieldName)
				text = $$("display-field-values.custom.splitter.text.hint-content", fields: fieldNames)

				content = new CUI.Label
					text: text
					markdown: true
				pop = new ez5.HintPopover
					element: textHintButton
					content: content
					padded: true
				pop.show()

		fields = [
			type: CUI.Input
			name: "text"
			min_rows: 3
			textarea: true
			maximize_horizontal: true
			form:
				label: $$("display-field-values.custom.splitter.text.label")
				hint: textHintButton
			onDataChanged: (_, field) =>
				CUI.Events.trigger
					node: field
					type: "content-resize"
				return
		]

		return fields

	renderField: (opts) ->
		dataOptions = @getDataOptions()
		if not dataOptions.text
			return

		data = opts.data
		fieldNames = @__getFieldNames(dataOptions)
		label = new CUI.Label(text: "", markdown: true)

		setText = =>
			values = @__getValues(data, fieldNames)
			if fieldNames.length > 0 and CUI.util.isEmpty(values)
				label.hide()
			else
				label.show()

			text = @__getLabelText(dataOptions.text, values)
			label.setText(text)
		setText()

		if opts.mode != "editor"
			return label

		for fieldName in fieldNames
			element = data["#{fieldName}:rendered"]?.getElement()
			if not element
				continue

			CUI.Events.listen
				type: "editor-changed"
				node: element
				call: =>
					setText()

		return label

	isEnabledForNested: ->
		return true

	__getLabelText: (text, values) ->
		for fieldName, value of values
			regexp = new RegExp("%#{fieldName}:best%", "g")
			text = text.replace(regexp, value)

			regexp = new RegExp("%#{fieldName}:urlencoded%", "g")
			text = text.replace(regexp, encodeURIComponent(value))

			regexp = new RegExp("%#{fieldName}%", "g")
			text = text.replace(regexp, value)
		return text

	__getValues: (data, fieldNames) ->
		values = {}
		for fieldName in fieldNames
			value = data[fieldName] or ""
			if CUI.util.isPlainObject(value)
				bestValue = ez5.loca.getBestFrontendValue(value)
				if not CUI.util.isEmpty(bestValue)
					values[fieldName] = bestValue
					continue
				value = Object.values(value).filter((_val) -> !!_val).join("-")

			if CUI.util.isEmpty(value)
				continue
			values[fieldName] = value
		return values

	__getFieldNames: (dataOptions) ->
		fieldNames = []
		text = dataOptions.text
		matches = text.matchAll(ez5.DisplayFieldValuesMaskSplitter.FIELD_NAMES_REGEXP)
		while values = matches.next()?.value
			if values[1]
				fieldName = values[1]
				fieldName = fieldName.replace(":best", "")
				fieldName = fieldName.replace(":urlencoded", "")
				fieldNames.push(fieldName)
		return fieldNames

MaskSplitter.plugins.registerPlugin(ez5.DisplayFieldValuesMaskSplitter)
