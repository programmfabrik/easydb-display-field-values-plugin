class ez5.DisplayFieldValuesMaskSplitter extends CustomMaskSplitter

	isSimpleSplit: ->
		return true

	renderAsField: ->
		return true

	getOptions: ->
		idObjecttype = @maskEditor.getMask().getTable().table_id

		dataFormData = {}

		textHintButton = new CUI.Button
			text: $$("display-field-values.custom.splitter.text.hint-text")
			appearance: "flat"
			onClick: =>
				_fields = @__getFieldNames(dataFormData)
				if _fields.length == 0
					text = $$("display-field-values.custom.splitter.text.hint-content-empty")
				else
					text = $$("display-field-values.custom.splitter.text.hint-content", fields: _fields)

				content = new CUI.Label
					text: text
					markdown: true
				pop = new ez5.HintPopover
					element: textHintButton
					content: content
					padded: true
				pop.show()

		fields = [
			type: CUI.DataForm
			name: "fields"
			form: label: $$("display-field-values.custom.splitter.form-field-selector.label")
			maximize_horizontal: true
			onDataChanged: (_, field) =>
				CUI.Events.trigger
					node: field
					type: "content-resize"
				return
			onDataInit: (_, data) ->
				dataFormData = data
			fields: [
				type: ez5.FieldSelector
				name: "field_name"
				store_value: "name"
				placeholder: $$("display-field-values.custom.splitter.options.field-selector.placeholder")
				maximize_horizontal: true
				objecttype_id: idObjecttype
				schema: "HEAD"
				filter: (field, data) =>
					if data.field_name != field.name() and dataFormData.fields.some((fieldData) -> fieldData.field_name == field.name())
						return false

					if not @father.children.some((_field) => _field.getData().field_name == field.name())
						return false

					return field instanceof TextColumn
			]
		,
			type: CUI.Input
			name: "text"
			textarea: true
			maximize_horizontal: true
			form:
				label: $$("display-field-values.custom.splitter.text.label")
				hint: textHintButton
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
			text = @__getLabelText(dataOptions.text, data, fieldNames)
			label.setText(text)
		setText()

		if opts.mode != "editor"
			return label

		for fieldName in fieldNames
			element = data["#{fieldName}:rendered"].getElement()
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

	__getLabelText: (text, data, fieldNames) ->
		for fieldName in fieldNames
			fieldNameRegexp = fieldName
			value = data[fieldName] or ""
			if CUI.util.isPlainObject(value)
				bestValue = ez5.loca.getBestFrontendValue(value)
				if not CUI.util.isEmpty(bestValue)
					regexp = new RegExp("%#{fieldNameRegexp}%:best", "g")
					text = text.replace(regexp, bestValue)
					continue
				value = Object.values(value).filter((_val) -> !!_val).join("-")

			if CUI.util.isEmpty(value)
				continue

			regexp = new RegExp("%#{fieldNameRegexp}%", "g")
			text = text.replace(regexp, value)

			regexp = new RegExp("%#{fieldNameRegexp}:urlencoded%", "g")
			text = text.replace(regexp, encodeURIComponent(value))
		return text

	__getFieldNames: (data) ->
		if not data?.fields
			return []
		return data.fields.filter((fieldData) -> !!fieldData.field_name).map((fieldData) -> fieldData.field_name)

MaskSplitter.plugins.registerPlugin(ez5.DisplayFieldValuesMaskSplitter)
