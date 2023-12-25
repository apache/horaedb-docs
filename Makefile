install:
	cargo install mdbook@0.4.36
	cargo install mdbook-i18n

serve:
	cd docs && mdbook serve

build:
	cd docs && mdbook build && ./move.sh

lint:
	find . -name '*.md' | xargs npx prettier@2.7.1 --write
