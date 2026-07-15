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
	manifest.yml

COFFEE_FILES = \
    src/webfrontend/MarkdownEscape.coffee \
    src/webfrontend/DisplayFieldValuesMaskSplitter.coffee \
    src/webfrontend/DisplayFieldValuesPDFNode.coffee

SCSS_FILES = src/webfrontend/scss/display-field-values.scss

all: build

include $(EASYDB_LIB)/tools/base-plugins.make

build: code $(L10N) css buildinfojson

code: $(JS)

clean: clean-base

wipe: wipe-base

# fylr: build an installable plugin zip. The top-level directory must equal the
# manifest plugin name ($(PLUGIN_NAME)); a URL/zip install rejects any other
# name (fylr internal/baseconfig/plugin_check.go). Layout mirrors what fylr
# loads from disk: manifest.yml + build/ (base_url_prefix defaults to
# build/webfrontend) + src/server (server-side callback scripts, if any).
zip: clean build
	rm -rf $(PLUGIN_NAME) $(PLUGIN_NAME).zip
	mkdir -p $(PLUGIN_NAME)
	cp -r build $(PLUGIN_NAME)/build
	cp manifest.yml build-info.json $(PLUGIN_NAME)/
	if [ -d src/server ]; then mkdir -p $(PLUGIN_NAME)/src && cp -r src/server $(PLUGIN_NAME)/src/server; fi
	zip -r $(PLUGIN_NAME).zip $(PLUGIN_NAME)
	rm -rf $(PLUGIN_NAME)
