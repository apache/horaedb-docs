install:
	cargo install mdbook@0.4.36

serve:
	cd docs && mdbook serve

build:
	cd docs && mdbook build

lint:
	find . -name '*.md' | xargs npx prettier@2.7.1 --write
