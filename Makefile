install:
	brew install hugo

serve:
	hugo serve

lint:
	find . -name '*.md' | xargs npx prettier@2.7.1 --write
