mod_name = spidertrons-manager
version = $(shell jq -r '.version' info.json)
factorio_mods_dir = /home/sheridan/software/factorio/mods
mod_dir = $(mod_name)_$(version)
zip_filename = $(mod_dir).zip

.PHONY: build deploy clean
all: build

build:
	@echo "Building $(zip_filename)..."
	@mkdir -p $(mod_dir)
	@rsync -av --exclude='$(mod_dir)' --exclude='$(zip_filename)' --exclude-from='build_exclude.txt' . $(mod_dir)
	@zip -r $(zip_filename) $(mod_dir)
	@rm -rf $(mod_dir)
	@echo "Build complete: $(zip_filename)"

deploy_internal: build
	@echo "Deploying $(zip_filename) to $(factorio_mods_dir)..."
	@cp $(zip_filename) $(factorio_mods_dir)
	@echo "Deployment complete."

clean:
	@echo "Cleaning up..."
	@rm -rf $(mod_dir) $(zip_filename)
	@echo "Cleanup complete."

deploy: deploy_internal clean
