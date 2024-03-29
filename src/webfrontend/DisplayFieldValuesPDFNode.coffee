if ez5.PdfCreator
	class ez5.PdfCreator.Node.DisplayFieldValue extends ez5.PdfCreator.Node

		@POOL_ATTR = ["name", "description", "contact"]
		@TOP_LEVEL_DATA = ["_system_object_id", "_global_object_id", "_uuid", "_created", "_last_modified", "_owner"]
		@ADDITIONAL_DATA = ["_version"]
		@getName: ->
			"displayFieldValue"

		__renderPdfContent: (opts) ->
			object = opts.object
			if not object
				return

			data = @getData()
			text = data.text
			replacements = @__getFieldNames(text)
			values = @__getValues(object[object._objecttype], replacements)

			if not @__hasAnyReplacement(data,values,opts)
				return

			replacementText = @__getLabelText(values)

			#Replacement for pool
			replacementText = @__poolReplacement(object[object._objecttype], replacementText)
			#Replacement for Top Level Data
			replacementText = @__topLevelDataReplacement(object, replacementText)

			replacementText = @__additionalDataReplacement(object[object._objecttype], replacementText)

			content = new CUI.MultilineLabel
				text: replacementText
				markdown: true

			return content

		__getSettingsFields: ->
			textHintButton = new CUI.Button
				text: $$("display-field-values.custom.splitter.text.hint-text")
				appearance: "flat"
				onClick: =>
					fieldNames = []
					for field in @__getMask().getFields("all")
						fieldName = field.name()
						if not fieldName or not field.FieldSchema?._column
							continue
						type = field.FieldSchema._column.type
						if type == "boolean"
							continue
						else if type == "eas"
							# TODO
							continue
						else if type == "daterange"
							fieldNames.push("#{fieldName}:from")
							fieldNames.push("#{fieldName}:to")
						else if type in ["text_l10n", "text_l10n_oneline"]
							fieldNames.push("#{fieldName}:best")
							for lang in ez5.loca.getDatabaseLanguages()
								fieldNames.push("#{fieldName}:#{lang}")
							continue
						else if type == "link"
							fieldNames.push("#{fieldName}:standard-1")
							fieldNames.push("#{fieldName}:standard-2")
							fieldNames.push("#{fieldName}:standard-3")
						else
							fieldNames.push(fieldName)

					# Add Pool placeholders
					if @__getMask().table.schema.pool_link
						for attr in ez5.DisplayFieldValuesMaskSplitter.POOL_ATTR
							fieldNames.push("pool.#{attr}")

					for topLevelData in ez5.DisplayFieldValuesMaskSplitter.TOP_LEVEL_DATA
						fieldNames.push("object.#{topLevelData}")

					for addData in ez5.DisplayFieldValuesMaskSplitter.ADDITIONAL_DATA
						fieldNames.push("object.#{addData}")

					fieldNames = fieldNames.concat(fieldNames.map((fieldName) -> "#{fieldName}:urlencoded")).sort()
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
				min_rows: 9
				textarea: true
				maximize_horizontal: true
				class: "ez5-display-field-values-text-input"
				form:
					label: $$("display-field-values.custom.splitter.text.label")
					hint: textHintButton
				onDataChanged: (_, field) =>
					CUI.Events.trigger
						node: field
						type: "content-resize"
					return
			,
				type: CUI.Checkbox
				name: "output_empty"
				form:
					label: $$("display-field-values.custom.splitter.output_empty.label")
			,
				type: CUI.Checkbox
				name: "dont_escape_markdown_in_values"
				form:
					label: $$("display-field-values.custom.splitter.dont_escape_markdown_in_values.label")
			]
			return fields

		__getLabelText: (values) ->
			data = @getData()
			text = data.text
			dontEscapeMarkdownInValues = data.dont_escape_markdown_in_values
			replacements = @__getFieldNames(text, false)

			doReplace = (field, _value) ->
				regexp = new RegExp("%#{field}:urlencoded%", "g")
				text = text.replace(regexp, encodeURI(_value))

				if not dontEscapeMarkdownInValues
					_value = MarkdownEscape.escape("#{_value}")

				regexp = new RegExp("%#{field}%", "g")
				text = text.replace(regexp, _value)

			for fieldName, value of values
				if CUI.util.isPlainObject(value)
					if value._standard
						for i in [1,2,3]
							if not value._standard[i]?.text
								continue
							bestValue = ez5.loca.getBestFrontendValue(value._standard[i].text)
							doReplace("#{fieldName}:standard-#{i}", bestValue)
					else
						bestValue = ez5.loca.getBestFrontendValue(value)
						if not CUI.util.isEmpty(bestValue)
							doReplace("#{fieldName}:best", bestValue)

						if not CUI.util.isEmpty(value.value) # For dates, for example.
							doReplace("#{fieldName}", value.value)

						for key, _value of value
							if CUI.util.isEmpty(_value) or CUI.util.isPlainObject(_value)
								continue
							_field = "#{fieldName}:#{key}"
							doReplace(_field, _value)
				else
					doReplace(fieldName, value)

			# Remove all unused placeholders with empty.
			for replacement in replacements
				regexp = new RegExp("%#{replacement}%", "g")
				text = text.replace(regexp, "")
			return text

		__getValues: (data, fieldNames) ->
			values = {}
			for fieldName in fieldNames
				value = data[fieldName]
				if CUI.util.isEmpty(value)
					continue

				if CUI.util.isPlainObject(value)
					if not Object.values(value).some((_val) -> not CUI.util.isEmpty(_val))
						continue

				values[fieldName] = value

			return values

		#This method return an array with all the fieldnames that
		__getFieldNames: (text, removeSuffix = true) ->
			fieldNames = new Set()
			matches = text.matchAll(ez5.DisplayFieldValuesMaskSplitter.FIELD_NAMES_REGEXP)
			while values = matches.next()?.value
				if values[1]
					fieldName = values[1]
					if removeSuffix
						fieldName = fieldName.replace(/:(.*)/g, "")
					fieldNames.add(fieldName)
			return Array.from(fieldNames)

		__topLevelDataReplacement: (topLevelData, text) ->
			if CUI.util.isEmpty(topLevelData)
				return text
			for topAttr in ez5.DisplayFieldValuesMaskSplitter.TOP_LEVEL_DATA
				if topAttr == "_owner"
					value = topLevelData[topAttr]?.user._generated_displayname
					if CUI.util.isEmpty(value)
						regexp = new RegExp("%object.#{topAttr}%", "g")
						text = text.replace(regexp, "")

						regexp = new RegExp("%object.#{topAttr}:urlencoded%", "g")
						text = text.replace(regexp, "")
						continue
				else
					value = topLevelData[topAttr]
					if topAttr in ["_created", "_last_modified"]
						value = ez5.format_date_and_time(value)

				regexp = new RegExp("%object.#{topAttr}%", "g")
				text = text.replace(regexp, value)

				regexp = new RegExp("%object.#{topAttr}:urlencoded%", "g")
				text = text.replace(regexp, encodeURI(value))

			return text

		__additionalDataReplacement: (data, text) ->
			if CUI.util.isEmpty(data)
				return text
			for addAttr in ez5.DisplayFieldValuesMaskSplitter.ADDITIONAL_DATA

				value = data[addAttr]

				regexp = new RegExp("%object.#{addAttr}%", "g")
				text = text.replace(regexp, value)

				regexp = new RegExp("%object.#{addAttr}:urlencoded%", "g")
				text = text.replace(regexp, encodeURI(value))

			return text


		__poolReplacement: (data, text) ->

			cleanAndReturn = =>
				for poolAttr in ez5.DisplayFieldValuesMaskSplitter.POOL_ATTR
					regexp = new RegExp("%pool.#{poolAttr}%", "g")
					text = text.replace(regexp, "")
					regexp = new RegExp("%pool.#{poolAttr}:urlencoded%", "g")
					text = text.replace(regexp, "")
				return text

			poolObj = ez5.pools.findPoolById(data._pool?.pool._id)

			if not poolObj
				return cleanAndReturn()

			poolData = poolObj.data.pool
			for poolAttr in ez5.DisplayFieldValuesMaskSplitter.POOL_ATTR
				value = poolData[poolAttr]
				if CUI.util.isEmpty(value)
					value = ""
				else if poolAttr == "contact"
					value = value.user?._generated_displayname or ""
				else
					value = ez5.loca.getBestFrontendValue(value)

				# We replace the pool attr
				regexp = new RegExp("%pool.#{poolAttr}%", "g")
				text = text.replace(regexp, value)

				# We replace the :urlencoded attribute
				regexp = new RegExp("%pool.#{poolAttr}:urlencoded%", "g")
				text = text.replace(regexp, encodeURI(value))

			return text

		__hasPoolReplacement: (opts) ->
			# Returns false if there is no pool_link.
			if not @__getMask().table.schema.pool_link
				return false

			dataOptions = @getData()
			text = dataOptions.text
			poolObj = ez5.pools.findPoolById(opts.object[opts.object._objecttype]._pool?.pool._id)
			poolData = poolObj.data.pool

			if not dataOptions.output_empty and text?.length > 0
				return true

			if not poolData
				return false

			for poolAttr in ez5.DisplayFieldValuesMaskSplitter.POOL_ATTR
				value = poolData[poolAttr]
				if text?.includes("%pool.#{poolAttr}%") and not CUI.util.isEmpty(value)
					return true

			return false;

		__hasAnyReplacement: (data,values, opts={}) ->

			if @__hasPoolReplacement(opts)
				return true

			if not CUI.util.isEmpty(values)
				return true

			for topAttr in ez5.DisplayFieldValuesMaskSplitter.TOP_LEVEL_DATA
				value = data[topAttr]
				if text?.includes("%object.#{topAttr}%") and not CUI.util.isEmpty(value)
					return true

			for addData in ez5.DisplayFieldValuesMaskSplitter.ADDITIONAL_DATA
				value = data[addData]
				if text?.includes("%object.#{addData}%") and not CUI.util.isEmpty(value)
					return true

			return false

	ez5.PdfCreator.plugins.registerPlugin(ez5.PdfCreator.Node.DisplayFieldValue)