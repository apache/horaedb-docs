install:
	cargo install mdbook
	cargo install mdbook-i18n --git https://github.com/chunshao90/mdbook-i18n.git --rev ee5d27989d35d266d5c9c5ccb6c2a863749b57c6 --force

serve:
	cd docs && mdbook serve

build:
	cd docs && mdbook build
