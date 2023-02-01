install:
	cargo install mdbook
	cargo install mdbook-i18n --git https://github.com/chunshao90/mdbook-i18n.git --rev 23c364c6a207d7beb8f8d2bf0b563ca55c367b44

serve:
	cd docs && mdbook serve

build:
	cd docs && mdbook build
