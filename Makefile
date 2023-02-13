install:
	cargo install mdbook@0.4.25
	cargo install mdbook-i18n --git https://github.com/chunshao90/mdbook-i18n.git --rev ca497cff369e0a5cedcd4024af6e1f05cc5050c5

serve:
	cd docs && mdbook serve

build:
	cd docs && mdbook build

lint:
	find . -name '*.md' | xargs npx prettier@2.7.1 --write
