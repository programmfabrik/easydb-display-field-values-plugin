PLUGIN_NAME = easydb-display-field-values
PLUGIN_PATH = easydb-display-field-values-plugin

EASYDB_LIB = easydb-library
L10N_FILES = l10n/$(PLUGIN_NAME).csv
L10N_GOOGLE_KEY = 1Z3UPJ6XqLBp-P8SUf-ewq4osNJ3iZWKJB83tc6Wrfn0
L10N_GOOGLE_GID = 1069433737

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(CSS) \
	$(JS) \
	easydb-display-field-values.yml

COFFEE_FILES = \
    src/webfrontend/MarkdownEscape.coffee \
    src/webfrontend/DisplayFieldValuesMaskSplitter.coffee

SCSS_FILES = src/webfrontend/scss/display-field-values.scss

all: build

include $(EASYDB_LIB)/tools/base-plugins.make

build: code $(L10N) css buildinfojson

code: $(JS)

clean: clean-base

wipe: wipe-base
