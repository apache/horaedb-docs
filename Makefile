install:
	cargo install mdbook@0.4.25
	cargo install mdbook-i18n --git https://github.com/chunshao90/mdbook-i18n.git --rev 802bf4c79633b0bcf403443b050e3b482db7b40d

serve:
	cd docs && mdbook serve

build:
	cd docs && mdbook build

lint:
	find . -name '*.md' | xargs npx prettier@2.7.1 --write
